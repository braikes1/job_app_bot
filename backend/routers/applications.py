import csv
import io
from typing import List, Optional

from fastapi import APIRouter, Depends, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from backend.db.database import get_db
from backend.models.user import User
from backend.models.application import JobApplication, ApplicationStatus
from backend.schemas.job import ApplicationOut
from backend.core.deps import get_current_user

router = APIRouter()


@router.get("/", response_model=List[ApplicationOut])
async def list_applications(
    status: Optional[ApplicationStatus] = Query(None),
    limit: int = Query(50, le=200),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    query = select(JobApplication).where(
        JobApplication.user_id == current_user.id
    ).order_by(desc(JobApplication.created_at)).limit(limit).offset(offset)

    if status:
        query = query.where(JobApplication.status == status)

    result = await db.execute(query)
    return result.scalars().all()


@router.get("/export/csv")
async def export_applications_csv(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(JobApplication)
        .where(JobApplication.user_id == current_user.id)
        .order_by(desc(JobApplication.created_at))
    )
    apps = result.scalars().all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow([
        "ID", "Job Title", "Company", "Status", "Match Score",
        "Applied At", "URL", "Created At"
    ])
    for app in apps:
        writer.writerow([
            app.id, app.job_title, app.company_name, app.status.value,
            app.match_score, app.applied_at, app.job_url, app.created_at,
        ])

    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=applications.csv"},
    )


@router.get("/{application_id}", response_model=ApplicationOut)
async def get_application(
    application_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(JobApplication).where(
            JobApplication.id == application_id,
            JobApplication.user_id == current_user.id,
        )
    )
    app = result.scalar_one_or_none()
    if not app:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Application not found")
    return app
