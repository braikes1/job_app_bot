from playwright.sync_api import sync_playwright
import time
import json
from pathlib import Path

SESSION_FILE = Path("data/linkedin_session.json")

def get_logged_in_context(browser):
    if SESSION_FILE.exists():
        context = browser.new_context(storage_state=json.loads(SESSION_FILE.read_text()))
        print("[✅] Loaded saved LinkedIn session")
    else:
        context = browser.new_context()
        page = context.new_page()
        print("[🔑] Please log in to LinkedIn manually...")
        page.goto("https://www.linkedin.com/login")
        page.wait_for_timeout(30000)
        session_state = context.storage_state()
        SESSION_FILE.write_text(json.dumps(session_state))
        print("[💾] Session saved for future use")
    return context

def test_auto_scroll_by_job_cards():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False, slow_mo=250)
        context = get_logged_in_context(browser)
        page = context.new_page()

        page.goto("https://www.linkedin.com/jobs/search/?keywords=Software%20Engineer%20remote")
        page.wait_for_timeout(8000)

        print("[🔍] Selecting job cards one-by-one to auto-scroll...")

        seen_count = 0
        scroll_attempts = 0
        max_attempts = 5

        while scroll_attempts < max_attempts:
            job_cards = page.locator("div.job-card-container--clickable")
            current_count = job_cards.count()

            print(f"[📋] Job cards detected: {current_count} (seen: {seen_count})")

            if current_count == seen_count:
                print("[↕️] No new jobs — scrolling down...")
                page.mouse.wheel(0, 4000)
                scroll_attempts += 1
                time.sleep(3)
                continue

            for i in range(seen_count, current_count):
                print(f"[🖱️] Clicking job card {i + 1}...")
                job_cards.nth(i).click(force=True)
                time.sleep(5)

            seen_count = current_count
            scroll_attempts = 0  # Reset scroll attempts if new jobs were loaded

        print("[✅] Done walking through all visible job cards.")
        browser.close()

if __name__ == "__main__":
    test_auto_scroll_by_job_cards()
