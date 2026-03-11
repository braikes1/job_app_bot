from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from backend.models.application import ApplicationStatus


class JobSearchRequest(BaseModel):
    keywords: str
    location: Optional[str] = "United States"
    remote_only: bool = False
    max_results: int = 20


class JobResult(BaseModel):
    title: str
    company: str
    location: Optional[str]
    url: str
    description: Optional[str]
    match_score: Optional[int] = None
    is_easy_apply: bool = False


class TailorRequest(BaseModel):
    profile_id: int
    job_url: str
    job_title: Optional[str] = None
    company_name: Optional[str] = None
    job_description: str


class TailorResponse(BaseModel):
    summary: str
    bullets: List[str]
    skills: List[str]
    match_score: int


class ApplyRequest(BaseModel):
    profile_id: int
    job_url: str
    job_title: Optional[str] = None
    company_name: Optional[str] = None
    job_description: Optional[str] = None
    tailored_summary: Optional[str] = None
    tailored_bullets: Optional[List[str]] = None
    tailored_skills: Optional[List[str]] = None


class ApplyStatusMessage(BaseModel):
    task_id: str
    step: str
    message: str
    progress: int  # 0-100
    done: bool = False
    success: Optional[bool] = None
    error: Optional[str] = None


class ApplicationOut(BaseModel):
    id: int
    user_id: int
    profile_id: Optional[int]
    job_title: Optional[str]
    company_name: Optional[str]
    job_url: str
    job_description: Optional[str]
    tailored_summary: Optional[str]
    tailored_bullets: Optional[List[str]]
    tailored_skills: Optional[List[str]]
    match_score: Optional[int]
    status: ApplicationStatus
    error_message: Optional[str]
    applied_at: Optional[datetime]
    created_at: datetime

    model_config = {"from_attributes": True}
