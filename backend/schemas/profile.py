from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List, Dict, Any
from datetime import datetime


class ProfileCreate(BaseModel):
    profile_name: str
    full_name: str
    email: EmailStr
    phone: Optional[str] = None
    location: Optional[str] = None
    linkedin_url: Optional[str] = None
    portfolio_url: Optional[str] = None
    github_url: Optional[str] = None
    knowledge_base: Optional[str] = None
    target_roles: Optional[List[str]] = Field(default_factory=list)
    preferred_remote: bool = True
    salary_min: Optional[int] = None
    salary_max: Optional[int] = None
    extra_answers: Optional[Dict[str, Any]] = Field(default_factory=dict)
    is_default: bool = False


class ProfileUpdate(BaseModel):
    profile_name: Optional[str] = None
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    location: Optional[str] = None
    linkedin_url: Optional[str] = None
    portfolio_url: Optional[str] = None
    github_url: Optional[str] = None
    knowledge_base: Optional[str] = None
    target_roles: Optional[List[str]] = None
    preferred_remote: Optional[bool] = None
    salary_min: Optional[int] = None
    salary_max: Optional[int] = None
    extra_answers: Optional[Dict[str, Any]] = None
    is_default: Optional[bool] = None


class ProfileOut(BaseModel):
    id: int
    user_id: int
    profile_name: str
    full_name: str
    email: str
    phone: Optional[str]
    location: Optional[str]
    linkedin_url: Optional[str]
    portfolio_url: Optional[str]
    github_url: Optional[str]
    resume_url: Optional[str]
    knowledge_base: Optional[str]
    target_roles: Optional[List[str]]
    preferred_remote: bool
    salary_min: Optional[int]
    salary_max: Optional[int]
    extra_answers: Optional[Dict[str, Any]]
    is_default: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
