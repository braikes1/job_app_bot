"""
OpenAI GPT-4o service for resume tailoring, job matching, and form field generation.
"""
import json
import logging
from typing import Optional
from openai import AsyncOpenAI

from backend.core.config import settings

logger = logging.getLogger(__name__)

_client: Optional[AsyncOpenAI] = None


def get_openai_client() -> AsyncOpenAI:
    global _client
    if _client is None:
        _client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
    return _client


async def tailor_resume(profile: dict, job_description: str) -> dict:
    """
    Uses GPT-4o to rewrite the user's resume summary and bullet points
    to best match a specific job description.
    """
    client = get_openai_client()

    system_prompt = (
        "You are an expert professional resume writer with 15+ years of experience. "
        "You specialize in tailoring resumes to specific job descriptions while maintaining authenticity. "
        "Always highlight transferable skills and use keywords from the job description."
    )

    user_prompt = f"""
Tailor this candidate's resume to the following job description.

CANDIDATE PROFILE:
Name: {profile.get('full_name', '')}
Target Roles: {', '.join(profile.get('target_roles', []))}
Knowledge Base / Experience: {profile.get('knowledge_base', '')}
Resume Text: {profile.get('resume_text', '')[:3000]}

JOB DESCRIPTION:
{job_description[:3000]}

Return a JSON object with exactly these fields:
{{
  "summary": "2-3 sentence professional summary tailored to this role",
  "bullets": ["achievement bullet 1", "achievement bullet 2", "...up to 6 bullets"],
  "skills": ["skill1", "skill2", "...up to 10 relevant skills"]
}}

Make every word count. Use action verbs. Include specific metrics where possible.
"""

    try:
        response = await client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            response_format={"type": "json_object"},
            temperature=0.7,
            max_tokens=1000,
        )
        return json.loads(response.choices[0].message.content)
    except Exception as e:
        logger.error(f"tailor_resume failed: {e}")
        return {"summary": "", "bullets": [], "skills": []}


async def score_job_match(profile: dict, job: dict) -> int:
    """
    Returns 0–100 match score between a user profile and a job posting.
    """
    client = get_openai_client()

    prompt = f"""
Rate how well this candidate matches this job on a scale of 0 to 100.

CANDIDATE:
Name: {profile.get('full_name')}
Target Roles: {', '.join(profile.get('target_roles', []))}
Experience: {profile.get('knowledge_base', '')[:1500]}

JOB:
Title: {job.get('title', '')}
Description: {job.get('description', '')[:1500]}

Return ONLY a JSON object: {{"score": <integer 0-100>, "reason": "<one sentence>"}}
"""

    try:
        response = await client.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"},
            temperature=0.3,
            max_tokens=100,
        )
        data = json.loads(response.choices[0].message.content)
        return int(data.get("score", 50))
    except Exception as e:
        logger.error(f"score_job_match failed: {e}")
        return 50


async def extract_form_fields(html: str, profile: dict) -> dict:
    """
    Analyzes application form HTML and returns a mapping of
    CSS selectors to the values that should be filled in.
    Uses GPT-4o to intelligently identify fields regardless of site structure.
    """
    client = get_openai_client()

    system_prompt = (
        "You are an expert web automation engineer. "
        "Analyze HTML forms and return precise CSS selectors for each form field. "
        "Always prefer the most specific and stable selectors (id > name > aria > class)."
    )

    user_prompt = f"""
Analyze this job application form HTML and return CSS selectors for each detected field,
mapped to the correct value from the candidate profile below.

CANDIDATE PROFILE:
{json.dumps({
    'email': profile.get('email'),
    'first_name': profile.get('full_name', '').split()[0] if profile.get('full_name') else '',
    'last_name': ' '.join(profile.get('full_name', '').split()[1:]) if profile.get('full_name') else '',
    'full_name': profile.get('full_name'),
    'phone': profile.get('phone'),
    'location': profile.get('location'),
    'linkedin_url': profile.get('linkedin_url'),
    'portfolio_url': profile.get('portfolio_url'),
    'github_url': profile.get('github_url'),
    **profile.get('extra_answers', {}),
})}

HTML (first 8000 chars):
{html[:8000]}

Return ONLY a JSON object where each key is a CSS selector string and each value is what to type:
{{
  "#email": "user@example.com",
  "input[name='firstName']": "John",
  ...
}}

Include ONLY fields that are clearly visible input fields, textareas, or selects.
Skip file upload fields, hidden fields, and checkboxes.
"""

    try:
        response = await client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            response_format={"type": "json_object"},
            temperature=0.2,
            max_tokens=800,
        )
        return json.loads(response.choices[0].message.content)
    except Exception as e:
        logger.error(f"extract_form_fields failed: {e}")
        return {}


async def find_apply_button(html: str) -> Optional[str]:
    """
    When no form fields are found, asks GPT-4o to locate an
    'Apply Now' or 'Start Application' button selector.
    """
    client = get_openai_client()

    prompt = f"""
Find the CSS selector for a button or link that starts or submits a job application.
It might say: 'Apply', 'Apply Now', 'Submit Application', 'Start Application', etc.

HTML (first 6000 chars):
{html[:6000]}

Return ONLY a JSON object: {{"selector": "<css selector or null>"}}
"""

    try:
        response = await client.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"},
            temperature=0.2,
            max_tokens=100,
        )
        data = json.loads(response.choices[0].message.content)
        return data.get("selector")
    except Exception as e:
        logger.error(f"find_apply_button failed: {e}")
        return None


async def generate_cover_letter(profile: dict, job_description: str) -> str:
    """
    Generates a tailored cover letter for a specific job posting.
    """
    client = get_openai_client()

    prompt = f"""
Write a concise, compelling cover letter (3 paragraphs, under 300 words) for this job.

CANDIDATE:
Name: {profile.get('full_name')}
Experience & Skills: {profile.get('knowledge_base', '')[:1500]}

JOB DESCRIPTION:
{job_description[:2000]}

Format as plain text, no placeholders, no brackets. Write in first person.
"""

    try:
        response = await client.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.8,
            max_tokens=500,
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        logger.error(f"generate_cover_letter failed: {e}")
        return ""
