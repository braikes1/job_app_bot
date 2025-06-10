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

def run_job_detection_and_scroll():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False, slow_mo=250)
        context = get_logged_in_context(browser)
        page = context.new_page()

        print("[🌐] Navigating to LinkedIn Jobs page...")
        page.goto("https://www.linkedin.com/jobs/search/?keywords=Software%20Engineer%20remote")
        page.wait_for_timeout(8000)

        seen_jobs = 0
        scroll_attempts = 0
        max_scroll_attempts = 5

        while scroll_attempts < max_scroll_attempts:
            job_cards = page.locator("div.job-card-container--clickable")
            total_cards = job_cards.count()
            print(f"[📋] Found {total_cards} job cards (seen: {seen_jobs})")

            if total_cards == seen_jobs:
                print("[🔄] No new cards — scrolling down...")
                page.mouse.wheel(0, 4000)
                scroll_attempts += 1
                time.sleep(3)
                continue

            for i in range(seen_jobs, total_cards):
                print(f"[🖱️] Clicking job card {i + 1}...")
                try:
                    job_cards.nth(i).click(force=True)
                    time.sleep(5)
                except Exception as e:
                    print(f"[⚠️] Error clicking job card {i + 1}: {e}")
                    continue

            seen_jobs = total_cards
            scroll_attempts = 0  # Reset scroll counter

        print("[✅] Job scroll and visit complete.")
        browser.close()

if __name__ == "__main__":
    run_job_detection_and_scroll()
