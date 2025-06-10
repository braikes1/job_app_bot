from playwright.sync_api import Page, BrowserContext, TimeoutError
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


def get_external_apply_jobs(page: Page, max_scrolls=5):
    external_jobs = []

    page.goto("https://www.linkedin.com/jobs/search/?keywords=Software%20Engineer%20remote")
    page.wait_for_timeout(5000)

    seen = 0
    scroll_attempts = 0

    while scroll_attempts < max_scrolls:
        job_cards = page.locator("div.job-card-container--clickable")
        total = job_cards.count()
        print(f"[📋] Job cards found: {total} (seen: {seen})")

        if total == seen:
            print("[↕️] Scrolling down...")
            page.mouse.wheel(0, 4000)
            scroll_attempts += 1
            time.sleep(3)
            continue

        for i in range(seen, total):
            try:
                job_card = job_cards.nth(i)
                print(f"[🖱️] Clicking job card {i + 1}...")
                job_card.click(force=True)
                time.sleep(5)

                apply_btn = page.locator('button.jobs-apply-button:has-text("Apply")').first
                if apply_btn and apply_btn.is_visible():
                    btn_text = apply_btn.inner_text().strip().lower()
                    if "easy" not in btn_text:
                        job_url = page.url
                        external_jobs.append(job_url)
                        print(f"[✅] External job saved: {job_url}")
                    else:
                        print("[⛔] Easy Apply detected — skipped")
                else:
                    print("[❌] No Apply button found")

            except Exception as e:
                print(f"[⚠️] Error on job {i + 1}: {e}")
                continue

        seen = total
        scroll_attempts = 0  # reset if new jobs found

    return list(set(external_jobs))


def visit_and_extract_apply_links(context: BrowserContext, linkedin_urls):
    apply_links = []
    page = context.new_page()

    for idx, url in enumerate(linkedin_urls):
        try:
            print(f"\n[🌐] Visiting job {idx + 1}: {url}")
            page.goto(url, timeout=20000)
            page.wait_for_timeout(3000)

            apply_btn = page.locator('button.jobs-apply-button:has-text("Apply")').first
            if apply_btn and apply_btn.is_visible():
                btn_text = apply_btn.inner_text().strip().lower()
                if "easy" not in btn_text:
                    with context.expect_page() as new_tab:
                        apply_btn.click()
                    time.sleep(6)
                    new_page = new_tab.value
                    new_page.wait_for_timeout(3000)

                    external_url = new_page.url
                    if "linkedin.com" not in external_url:
                        print(f"[🌍] External site: {external_url}")
                        apply_links.append(external_url)
                    else:
                        print("[↩️] Still on LinkedIn — skipped")

                    new_page.close()
                else:
                    print("[⛔] Easy Apply detected — skipped")
            else:
                print("[❌] No Apply button")

        except TimeoutError:
            print(f"[⏳] Timeout on job: {url}")
        except Exception as e:
            print(f"[❗] Error: {e}")

    page.close()
    return list(set(apply_links))
