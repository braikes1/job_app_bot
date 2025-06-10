from playwright.sync_api import sync_playwright, TimeoutError
from pathlib import Path
import time
import json

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


def combined_scroll_and_apply():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False, slow_mo=250)
        context = get_logged_in_context(browser)
        page = context.new_page()

        page.goto("https://www.linkedin.com/jobs/search/?keywords=Software%20Engineer%20remote")
        page.wait_for_timeout(8000)

        print("[🔍] Detecting job cards and applying...")
        seen_count = 0
        scroll_attempts = 0
        max_attempts = 5

        while scroll_attempts < max_attempts:
            job_cards = page.locator("div.job-card-container--clickable")
            total_cards = job_cards.count()
            print(f"[📋] Job cards detected: {total_cards} (seen: {seen_count})")

            if total_cards == seen_count:
                print("[↕️] No new jobs — scrolling down...")
                page.mouse.wheel(0, 4000)
                scroll_attempts += 1
                time.sleep(3)
                continue

            for i in range(seen_count, total_cards):
                try:
                    print(f"[🖱️] Clicking job card {i + 1}...")
                    job_cards.nth(i).click(force=True)
                    time.sleep(5)

                    apply_btn = page.locator('button.jobs-apply-button:has-text("Apply")').first

                    if apply_btn and apply_btn.is_visible():
                        text = apply_btn.inner_text().strip().lower()
                        if "easy" not in text:
                            print("[🚀] External Apply found — clicking...")
                            with context.expect_page() as new_tab:
                                apply_btn.click()
                            new_page = new_tab.value
                            new_page.wait_for_timeout(3000)
                            print(f"[🌍] Landed on: {new_page.url}")
                            new_page.close()
                        else:
                            print("[⛔] Easy Apply detected — skipping")
                    else:
                        print("[❌] No Apply button on this job")

                except Exception as e:
                    print(f"[❗] Error on job {i + 1}: {e}")
                    continue

            seen_count = total_cards
            scroll_attempts = 0  # Reset if new cards were found

        print("[✅] All visible job cards processed.")
        browser.close()


if __name__ == "__main__":
    combined_scroll_and_apply()
