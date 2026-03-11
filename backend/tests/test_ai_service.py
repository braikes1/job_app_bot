"""
Unit tests for AI service (mocked OpenAI calls).
Run: pytest backend/tests/test_ai_service.py -v
"""
import json
import pytest
from unittest.mock import AsyncMock, patch, MagicMock


MOCK_PROFILE = {
    "full_name": "Bryan Raikes",
    "email": "bryan@example.com",
    "phone": "954-555-0000",
    "location": "Davie, FL",
    "target_roles": ["Software Engineer", "Full Stack Developer"],
    "knowledge_base": "5 years Python, React, FastAPI, PostgreSQL",
    "resume_text": "Bryan Raikes - Software Engineer - Python, React, FastAPI",
    "extra_answers": {"citizenship": "U.S. Citizen"},
}

MOCK_JOB_DESC = "We are hiring a Full Stack Developer with Python and React experience."


@pytest.mark.asyncio
async def test_tailor_resume_returns_dict():
    mock_response = MagicMock()
    mock_response.choices[0].message.content = json.dumps({
        "summary": "Experienced developer tailored summary",
        "bullets": ["Built REST APIs", "Developed React UIs"],
        "skills": ["Python", "React", "FastAPI"],
    })

    with patch("backend.services.ai_service.get_openai_client") as mock_client:
        mock_client.return_value.chat.completions.create = AsyncMock(return_value=mock_response)

        from backend.services.ai_service import tailor_resume
        result = await tailor_resume(MOCK_PROFILE, MOCK_JOB_DESC)

    assert "summary" in result
    assert "bullets" in result
    assert isinstance(result["bullets"], list)


@pytest.mark.asyncio
async def test_score_job_match_returns_int():
    mock_response = MagicMock()
    mock_response.choices[0].message.content = json.dumps({"score": 87, "reason": "Strong match"})

    with patch("backend.services.ai_service.get_openai_client") as mock_client:
        mock_client.return_value.chat.completions.create = AsyncMock(return_value=mock_response)

        from backend.services.ai_service import score_job_match
        score = await score_job_match(MOCK_PROFILE, {"title": "Full Stack Dev", "description": MOCK_JOB_DESC})

    assert isinstance(score, int)
    assert 0 <= score <= 100


@pytest.mark.asyncio
async def test_extract_form_fields_returns_dict():
    mock_response = MagicMock()
    mock_response.choices[0].message.content = json.dumps({
        "input[name='email']": "bryan@example.com",
        "#firstName": "Bryan",
        "#lastName": "Raikes",
    })

    sample_html = """
    <form>
        <input type="email" name="email" />
        <input type="text" id="firstName" />
        <input type="text" id="lastName" />
        <button type="submit">Apply</button>
    </form>
    """

    with patch("backend.services.ai_service.get_openai_client") as mock_client:
        mock_client.return_value.chat.completions.create = AsyncMock(return_value=mock_response)

        from backend.services.ai_service import extract_form_fields
        fields = await extract_form_fields(sample_html, MOCK_PROFILE)

    assert isinstance(fields, dict)
    assert len(fields) > 0
