from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List

from backend.db.database import get_db
from backend.models.user import User
from backend.models.profile import Profile
from backend.schemas.profile import ProfileCreate, ProfileUpdate, ProfileOut
from backend.core.deps import get_current_user
from backend.services.resume_service import parse_pdf_text
from backend.services.storage_service import upload_resume

router = APIRouter()


@router.get("/", response_model=List[ProfileOut])
async def list_profiles(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Profile).where(Profile.user_id == current_user.id))
    return result.scalars().all()


@router.post("/", response_model=ProfileOut, status_code=status.HTTP_201_CREATED)
async def create_profile(
    body: ProfileCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if body.is_default:
        await _clear_default_flags(current_user.id, db)

    profile = Profile(**body.model_dump(), user_id=current_user.id)
    db.add(profile)
    await db.commit()
    await db.refresh(profile)
    return profile


@router.get("/{profile_id}", response_model=ProfileOut)
async def get_profile(
    profile_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile = await _get_owned_profile(profile_id, current_user.id, db)
    return profile


@router.patch("/{profile_id}", response_model=ProfileOut)
async def update_profile(
    profile_id: int,
    body: ProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile = await _get_owned_profile(profile_id, current_user.id, db)

    if body.is_default:
        await _clear_default_flags(current_user.id, db)

    update_data = body.model_dump(exclude_unset=True)
    for key, val in update_data.items():
        setattr(profile, key, val)

    await db.commit()
    await db.refresh(profile)
    return profile


@router.delete("/{profile_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_profile(
    profile_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile = await _get_owned_profile(profile_id, current_user.id, db)
    await db.delete(profile)
    await db.commit()


@router.post("/{profile_id}/resume", response_model=ProfileOut)
async def upload_resume_file(
    profile_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if file.content_type != "application/pdf":
        raise HTTPException(status_code=400, detail="Only PDF files are accepted")

    profile = await _get_owned_profile(profile_id, current_user.id, db)
    content = await file.read()

    # Parse PDF text for GPT context
    resume_text = parse_pdf_text(content)

    # Upload to cloud storage
    resume_url = await upload_resume(
        file_bytes=content,
        filename=f"user_{current_user.id}/profile_{profile_id}_{file.filename}",
    )

    profile.resume_text = resume_text
    profile.resume_url = resume_url
    await db.commit()
    await db.refresh(profile)
    return profile


# --- Helpers ---

async def _get_owned_profile(profile_id: int, user_id: int, db: AsyncSession) -> Profile:
    result = await db.execute(
        select(Profile).where(Profile.id == profile_id, Profile.user_id == user_id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile


async def _clear_default_flags(user_id: int, db: AsyncSession):
    result = await db.execute(
        select(Profile).where(Profile.user_id == user_id, Profile.is_default == True)  # noqa: E712
    )
    for p in result.scalars().all():
        p.is_default = False
    await db.flush()
