"""
Integration tests for auth endpoints.
Run: pytest backend/tests/test_auth.py -v
Requires a running PostgreSQL instance (or use SQLite for testing).
"""
import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

from backend.main import app
from backend.db.database import Base, get_db

TEST_DB_URL = "sqlite+aiosqlite:///./test_jobbot.db"


@pytest.fixture(scope="session")
async def test_db_engine():
    engine = create_async_engine(TEST_DB_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest.fixture
async def client(test_db_engine):
    test_session_maker = async_sessionmaker(test_db_engine, class_=AsyncSession, expire_on_commit=False)

    async def override_get_db():
        async with test_session_maker() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_register(client):
    response = await client.post("/auth/register", json={
        "email": "test@example.com",
        "password": "securepassword123",
        "full_name": "Test User",
    })
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data


@pytest.mark.asyncio
async def test_login(client):
    await client.post("/auth/register", json={
        "email": "login@example.com",
        "password": "mypassword",
        "full_name": "Login User",
    })
    response = await client.post("/auth/login", json={
        "email": "login@example.com",
        "password": "mypassword",
    })
    assert response.status_code == 200
    assert "access_token" in response.json()


@pytest.mark.asyncio
async def test_duplicate_register(client):
    data = {"email": "dup@example.com", "password": "pass", "full_name": "Dup"}
    await client.post("/auth/register", json=data)
    response = await client.post("/auth/register", json=data)
    assert response.status_code == 409


@pytest.mark.asyncio
async def test_get_me(client):
    reg = await client.post("/auth/register", json={
        "email": "me@example.com", "password": "pass123", "full_name": "Me"
    })
    token = reg.json()["access_token"]
    response = await client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    assert response.json()["email"] == "me@example.com"
