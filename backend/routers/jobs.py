import asyncio
import uuid
from datetime import datetime, timezone
from typing import List

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from backend.db.database import get_db, AsyncSessionLocal
from backend.models.user import User
from backend.models.profile import Profile
from backend.models.application import JobApplication, ApplicationStatus
from backend.schemas.job import (
    JobSearchRequest, JobResult, TailorRequest, TailorResponse,
    ApplyRequest, ApplyStatusMessage, ApplicationOut,
)
from backend.core.deps import get_current_user
from backend.services.ai_service import tailor_resume, score_job_match
from backend.services.automation_service import run_apply_automation

router = APIRouter()

# In-memory task queue for WebSocket status updates
# In production, replace with Redis pub/sub
_task_queues: dict[str, asyncio.Queue] = {}


@router.get("/search", response_model=List[JobResult])
async def search_jobs(
    keywords: str,
    location: str = "United States",
    remote_only: bool = False,
    max_results: int = 20,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Searches LinkedIn for jobs matching keywords/location using Playwright,
    then scores each result against the user's default profile using GPT-4o.
    """
    from backend.services.automation_service import search_jobs_on_linkedin

    result = await db.execute(
        select(Profile).where(
            Profile.user_id == current_user.id,
            Profile.is_default == True,  # noqa: E712
        )
    )
    profile = result.scalar_one_or_none()
    if not profile:
        # Fall back to first profile
        result = await db.execute(select(Profile).where(Profile.user_id == current_user.id))
        profile = result.scalars().first()

    jobs = await search_jobs_on_linkedin(keywords=keywords, location=location, max_results=max_results)

    # Score each job if profile exists
    if profile:
        profile_dict = _profile_to_dict(profile)
        scored = []
        for job in jobs:
            score = await score_job_match(profile_dict, {"title": job.get("title"), "description": job.get("description", "")})
            scored.append(JobResult(
                title=job.get("title", ""),
                company=job.get("company", ""),
                location=job.get("location"),
                url=job.get("url", ""),
                description=job.get("description"),
                match_score=score,
                is_easy_apply=job.get("is_easy_apply", False),
            ))
        return sorted(scored, key=lambda x: x.match_score or 0, reverse=True)

    return [JobResult(**job) for job in jobs]


@router.post("/tailor", response_model=TailorResponse)
async def tailor_job(
    body: TailorRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Profile).where(Profile.id == body.profile_id, Profile.user_id == current_user.id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    profile_dict = _profile_to_dict(profile)
    tailored = await tailor_resume(profile_dict, body.job_description)
    score = await score_job_match(profile_dict, {"title": body.job_title, "description": body.job_description})

    return TailorResponse(
        summary=tailored.get("summary", ""),
        bullets=tailored.get("bullets", []),
        skills=tailored.get("skills", []),
        match_score=score,
    )


@router.post("/apply/start", response_model=dict)
async def start_apply(
    body: ApplyRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Profile).where(Profile.id == body.profile_id, Profile.user_id == current_user.id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    # Create application record
    application = JobApplication(
        user_id=current_user.id,
        profile_id=body.profile_id,
        job_title=body.job_title,
        company_name=body.company_name,
        job_url=body.job_url,
        job_description=body.job_description,
        tailored_summary=body.tailored_summary,
        tailored_bullets=body.tailored_bullets,
        tailored_skills=body.tailored_skills,
        status=ApplicationStatus.PENDING,
    )
    db.add(application)
    await db.commit()
    await db.refresh(application)

    # Create a task queue for WebSocket
    task_id = str(uuid.uuid4())
    queue: asyncio.Queue = asyncio.Queue()
    _task_queues[task_id] = queue

    # Run automation in background
    asyncio.create_task(
        _run_apply_task(
            task_id=task_id,
            application_id=application.id,
            profile=profile,
            body=body,
            queue=queue,
        )
    )

    return {"task_id": task_id, "application_id": application.id}


@router.websocket("/apply/ws/{task_id}")
async def apply_status_ws(websocket: WebSocket, task_id: str):
    await websocket.accept()
    queue = _task_queues.get(task_id)
    if not queue:
        await websocket.send_json({"error": "Task not found"})
        await websocket.close()
        return

    try:
        while True:
            msg: ApplyStatusMessage = await asyncio.wait_for(queue.get(), timeout=120)
            await websocket.send_json(msg.model_dump())
            if msg.done:
                break
    except (asyncio.TimeoutError, WebSocketDisconnect):
        pass
    finally:
        _task_queues.pop(task_id, None)
        await websocket.close()


# --- Background task ---

async def _run_apply_task(
    task_id: str,
    application_id: int,
    profile: Profile,
    body: ApplyRequest,
    queue: asyncio.Queue,
):
    async def emit(step: str, message: str, progress: int, done: bool = False,
                   success: bool = None, error: str = None):
        await queue.put(ApplyStatusMessage(
            task_id=task_id, step=step, message=message,
            progress=progress, done=done, success=success, error=error,
        ))

    async with AsyncSessionLocal() as db:
        try:
            await emit("connecting", "Connecting to job site...", 10)

            profile_dict = _profile_to_dict(profile)
            fill_data = {
                **profile_dict,
                "tailored_summary": body.tailored_summary,
                "tailored_bullets": body.tailored_bullets,
                "tailored_skills": body.tailored_skills,
            }

            await emit("filling", "Analyzing application form...", 30)

            loop = asyncio.get_event_loop()
            success = await run_apply_automation(
                job_url=body.job_url,
                profile=fill_data,
                on_step=lambda step, msg, pct: asyncio.run_coroutine_threadsafe(
                    emit(step, msg, pct), loop
                ).result(timeout=5),
            )

            result = await db.execute(
                select(JobApplication).where(JobApplication.id == application_id)
            )
            application = result.scalar_one_or_none()
            if application:
                application.status = ApplicationStatus.SUBMITTED if success else ApplicationStatus.FAILED
                application.applied_at = datetime.now(timezone.utc) if success else None
                await db.commit()

            await emit(
                "done", "Application submitted!" if success else "Application failed",
                100, done=True, success=success,
            )

        except Exception as exc:
            result = await db.execute(
                select(JobApplication).where(JobApplication.id == application_id)
            )
            application = result.scalar_one_or_none()
            if application:
                application.status = ApplicationStatus.FAILED
                application.error_message = str(exc)
                await db.commit()

            await emit("error", f"Error: {exc}", 0, done=True, success=False, error=str(exc))



def _profile_to_dict(profile: Profile) -> dict:
    return {
        "full_name": profile.full_name,
        "email": profile.email,
        "phone": profile.phone or "",
        "location": profile.location or "",
        "linkedin_url": profile.linkedin_url or "",
        "portfolio_url": profile.portfolio_url or "",
        "github_url": profile.github_url or "",
        "resume_text": profile.resume_text or "",
        "knowledge_base": profile.knowledge_base or "",
        "target_roles": profile.target_roles or [],
        "salary_min": profile.salary_min,
        "salary_max": profile.salary_max,
        "extra_answers": profile.extra_answers or {},
    }
