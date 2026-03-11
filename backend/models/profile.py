from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, Text, Boolean, Integer, DateTime, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.db.database import Base


class Profile(Base):
    __tablename__ = "profiles"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)

    # Identity
    profile_name: Mapped[str] = mapped_column(String(100), nullable=False)  # e.g. "Software Engineer"
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[str] = mapped_column(String(255), nullable=False)
    phone: Mapped[Optional[str]] = mapped_column(String(50))
    location: Mapped[Optional[str]] = mapped_column(String(255))

    # Links
    linkedin_url: Mapped[Optional[str]] = mapped_column(String(500))
    portfolio_url: Mapped[Optional[str]] = mapped_column(String(500))
    github_url: Mapped[Optional[str]] = mapped_column(String(500))

    # Resume
    resume_url: Mapped[Optional[str]] = mapped_column(String(1000))  # S3/R2 URL
    resume_text: Mapped[Optional[str]] = mapped_column(Text)          # Parsed PDF text

    # Knowledge base (free-form text for GPT context)
    knowledge_base: Mapped[Optional[str]] = mapped_column(Text)

    # Job preferences
    target_roles: Mapped[Optional[list]] = mapped_column(JSON, default=list)
    preferred_remote: Mapped[bool] = mapped_column(Boolean, default=True)
    salary_min: Mapped[Optional[int]] = mapped_column(Integer)
    salary_max: Mapped[Optional[int]] = mapped_column(Integer)

    # Additional form-fill answers (stored as JSON for extensibility)
    extra_answers: Mapped[Optional[dict]] = mapped_column(JSON, default=dict)
    # e.g. {"citizenship": "U.S. Citizen", "felony": "No", "degree": "B.S."}

    is_default: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    user: Mapped["User"] = relationship("User", back_populates="profiles")  # noqa: F821
    applications: Mapped[list["JobApplication"]] = relationship(  # noqa: F821
        "JobApplication", back_populates="profile"
    )
