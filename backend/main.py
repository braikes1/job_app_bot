"""
Job Bot API — FastAPI entrypoint.
Run locally: uvicorn backend.main:app --reload --port 8000
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.core.config import settings
from backend.db.database import create_tables
from backend.routers import auth, profiles, jobs, applications

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting Job Bot API...")
    await create_tables()
    logger.info("Database tables ready")
    yield
    logger.info("Shutting down Job Bot API")


app = FastAPI(
    title="Job Bot API",
    version="1.0.0",
    description="AI-powered job application automation backend",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.get_cors_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/auth", tags=["Auth"])
app.include_router(profiles.router, prefix="/profiles", tags=["Profiles"])
app.include_router(jobs.router, prefix="/jobs", tags=["Jobs"])
app.include_router(applications.router, prefix="/applications", tags=["Applications"])


@app.get("/health")
async def health_check():
    return {"status": "ok", "version": "1.0.0"}
