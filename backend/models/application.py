from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, Text, DateTime, ForeignKey, JSON, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship
import enum

from backend.db.database import Base


class ApplicationStatus(str, enum.Enum):
    PENDING = "pending"
    SUBMITTED = "submitted"
    FAILED = "failed"
    SKIPPED = "skipped"


class JobApplication(Base):
    __tablename__ = "job_applications"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    profile_id: Mapped[Optional[int]] = mapped_column(ForeignKey("profiles.id"), nullable=True)

    # Job info
    job_title: Mapped[Optional[str]] = mapped_column(String(255))
    company_name: Mapped[Optional[str]] = mapped_column(String(255))
    job_url: Mapped[str] = mapped_column(String(1000), nullable=False)
    job_description: Mapped[Optional[str]] = mapped_column(Text)

    # AI output
    tailored_summary: Mapped[Optional[str]] = mapped_column(Text)
    tailored_bullets: Mapped[Optional[list]] = mapped_column(JSON)
    tailored_skills: Mapped[Optional[list]] = mapped_column(JSON)
    match_score: Mapped[Optional[int]] = mapped_column()

    # Status
    status: Mapped[ApplicationStatus] = mapped_column(
        Enum(ApplicationStatus), default=ApplicationStatus.PENDING
    )
    error_message: Mapped[Optional[str]] = mapped_column(Text)

    applied_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    user: Mapped["User"] = relationship("User", back_populates="applications")  # noqa: F821
    profile: Mapped[Optional["Profile"]] = relationship(  # noqa: F821
        "Profile", back_populates="applications"
    )
