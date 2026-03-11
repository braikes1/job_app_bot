"""
Playwright browser automation service.
Adapted from the existing core/session_handler.py and core/gemini_filler.py,
now powered by OpenAI GPT-4o instead of Gemini.
"""
import asyncio
import json
import logging
import time
from pathlib import Path
from typing import Callable, Optional

from backend.core.config import settings
from backend.services.ai_service import extract_form_fields, find_apply_button

logger = logging.getLogger(__name__)

SESSION_FILE = Path(settings.LINKEDIN_SESSION_FILE)


async def run_apply_automation(
    job_url: str,
    profile: dict,
    on_step: Optional[Callable] = None,
) -> bool:
    """
    Opens the job application URL in a headless browser,
    uses GPT-4o to identify form fields, fills them, and submits.

    Returns True on success, False on failure.

    on_step(step: str, message: str, progress: int) is called to emit status updates.
    """

    async def emit(step: str, msg: str, pct: int):
        if on_step:
            try:
                await on_step(step, msg, pct)
            except Exception:
                pass

    try:
        # Playwright must run in a thread executor because it uses sync API
        loop = asyncio.get_event_loop()
        result = await loop.run_in_executor(
            None,
            _sync_apply,
            job_url,
            profile,
            emit,
            loop,
        )
        return result
    except Exception as e:
        logger.error(f"run_apply_automation failed: {e}")
        return False


def _sync_apply(
    job_url: str,
    profile: dict,
    emit_coro: Callable,
    loop: asyncio.AbstractEventLoop,
) -> bool:
    """
    Synchronous Playwright execution (runs in thread executor).
    """
    from playwright.sync_api import sync_playwright

    def emit(step: str, msg: str, pct: int):
        asyncio.run_coroutine_threadsafe(emit_coro(step, msg, pct), loop)

    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True, slow_mo=100)
            context = _load_or_create_context(browser)
            page = context.new_page()

            emit("connecting", f"Opening {job_url[:60]}...", 15)
            page.goto(job_url, timeout=45000)
            page.wait_for_timeout(3000)

            emit("analyzing", "Analyzing application form...", 30)
            html = page.content()

            # Ask GPT-4o to map selectors → values
            selector_map = asyncio.run_coroutine_threadsafe(
                extract_form_fields(html, profile), loop
            ).result(timeout=30)

            if selector_map:
                emit("filling", f"Filling {len(selector_map)} form fields...", 50)
                filled_count = 0
                total = len(selector_map)

                for selector, value in selector_map.items():
                    if not value:
                        continue
                    try:
                        element = page.query_selector(selector)
                        if element and element.is_visible():
                            tag = element.evaluate("el => el.tagName.toLowerCase()")
                            input_type = element.get_attribute("type") or ""

                            if tag == "select":
                                page.select_option(selector, label=str(value))
                            elif input_type in ("radio", "checkbox"):
                                pass  # Skip for now — requires special handling
                            else:
                                page.fill(selector, str(value))

                            filled_count += 1
                            progress = 50 + int((filled_count / total) * 30)
                            emit("filling", f"Filled: {selector}", progress)
                            time.sleep(0.3)
                    except Exception as e:
                        logger.warning(f"Could not fill {selector}: {e}")

                emit("filled", f"Filled {filled_count}/{total} fields", 80)

            else:
                emit("navigating", "No form found — looking for Apply button...", 50)
                apply_selector = asyncio.run_coroutine_threadsafe(
                    find_apply_button(html), loop
                ).result(timeout=20)

                if apply_selector:
                    try:
                        page.click(apply_selector)
                        page.wait_for_timeout(5000)
                        emit("navigating", "Clicked Apply button", 70)
                    except Exception as e:
                        logger.warning(f"Could not click apply button {apply_selector}: {e}")

            # Attempt to find and click submit button
            emit("submitting", "Looking for submit button...", 85)
            submitted = _try_submit(page)

            emit("done", "Application submitted!" if submitted else "Reached final step", 100)
            browser.close()
            return submitted

    except Exception as e:
        logger.error(f"_sync_apply error: {e}")
        return False


def _load_or_create_context(browser):
    """Loads saved LinkedIn session or creates a new browser context."""
    if SESSION_FILE.exists():
        try:
            state = json.loads(SESSION_FILE.read_text())
            context = browser.new_context(storage_state=state)
            logger.info("Loaded saved browser session")
            return context
        except Exception as e:
            logger.warning(f"Could not load session: {e}")

    return browser.new_context(
        viewport={"width": 1280, "height": 900},
        user_agent=(
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/120.0.0.0 Safari/537.36"
        ),
    )


def _try_submit(page) -> bool:
    """
    Attempts to click a submit/apply button on the current page.
    Tries a series of common selectors.
    """
    submit_selectors = [
        "button[type='submit']",
        "input[type='submit']",
        "button:has-text('Submit')",
        "button:has-text('Apply')",
        "button:has-text('Send Application')",
        "button:has-text('Complete Application')",
        "[data-testid='submit-button']",
        ".submit-btn",
        "#submit",
    ]

    for selector in submit_selectors:
        try:
            btn = page.locator(selector).first
            if btn and btn.is_visible():
                btn.click()
                page.wait_for_timeout(3000)
                logger.info(f"Clicked submit button: {selector}")
                return True
        except Exception:
            continue

    return False


async def search_jobs_on_linkedin(
    keywords: str,
    location: str = "United States",
    max_results: int = 20,
) -> list[dict]:
    """
    Searches LinkedIn for jobs and returns basic metadata (title, company, url).
    Adapted from the existing platforms/linkedin.py search logic.
    """
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(
        None,
        _sync_search_jobs,
        keywords,
        location,
        max_results,
    )


def _sync_search_jobs(keywords: str, location: str, max_results: int) -> list[dict]:
    from playwright.sync_api import sync_playwright
    import time as _time

    jobs = []
    url = f"https://www.linkedin.com/jobs/search/?keywords={keywords}&location={location}&f_AL=false"

    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            context = _load_or_create_context(browser)
            page = context.new_page()

            page.goto(url, timeout=45000)
            page.wait_for_timeout(4000)

            seen = set()
            scroll_count = 0

            while len(jobs) < max_results and scroll_count < 10:
                cards = page.locator("ul.jobs-search__results-list li")
                count = cards.count()

                for i in range(count):
                    if len(jobs) >= max_results:
                        break

                    card = cards.nth(i)
                    job_id = card.get_attribute("data-entity-urn") or str(i)
                    if job_id in seen:
                        continue
                    seen.add(job_id)

                    try:
                        title_el = card.locator("h3").first
                        company_el = card.locator("h4").first
                        location_el = card.locator(".job-search-card__location").first

                        title = title_el.inner_text().strip() if title_el else ""
                        company = company_el.inner_text().strip() if company_el else ""
                        loc = location_el.inner_text().strip() if location_el else ""

                        link_el = card.locator("a[href*='/jobs/view/']").first
                        href = link_el.get_attribute("href") if link_el else ""
                        job_url = f"https://www.linkedin.com{href}" if href and href.startswith("/") else href

                        if title and job_url:
                            jobs.append({
                                "title": title,
                                "company": company,
                                "location": loc,
                                "url": job_url,
                                "description": None,
                                "is_easy_apply": False,
                            })
                    except Exception as e:
                        logger.warning(f"Error parsing job card: {e}")

                page.mouse.wheel(0, 3000)
                page.wait_for_timeout(2000)
                scroll_count += 1

            browser.close()
    except Exception as e:
        logger.error(f"LinkedIn search failed: {e}")

    return jobs


async def save_linkedin_session(page) -> bool:
    """
    Saves the current browser session state to disk for reuse.
    Called after a successful LinkedIn login.
    """
    try:
        SESSION_FILE.parent.mkdir(parents=True, exist_ok=True)
        state = page.context.storage_state()
        SESSION_FILE.write_text(json.dumps(state))
        logger.info(f"LinkedIn session saved to {SESSION_FILE}")
        return True
    except Exception as e:
        logger.error(f"Failed to save session: {e}")
        return False
