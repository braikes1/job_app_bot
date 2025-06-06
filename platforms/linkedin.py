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


def search_linkedin_jobs(keywords, location="Remote", pages=2, custom_url=None):
    job_links = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False, slow_mo=250)
        context = get_logged_in_context(browser)
        page = context.new_page()

        search_url = custom_url or f"https://www.linkedin.com/jobs/search/?keywords={keywords}&location={location}&f_AL=false"
        page.goto(search_url)
        page.wait_for_timeout(5000)

        print("[⬇️] Scrolling to load job results...")
        for _ in range(pages):
            page.mouse.wheel(0, 5000)
            page.wait_for_timeout(3000)

        print("[📌] Finding all job cards...")
        job_cards = page.locator("div.job-card-container--clickable")
        count = job_cards.count()
        print(f"[📋] Found {count} job cards")

        for i in range(count):
            try:
                print(f"[🖱️] Clicking job card {i + 1}...")
                job_cards.nth(i).click(force=True)
                time.sleep(7)  # 🔁 Delay after job card click

                apply_btn = page.locator('button.jobs-apply-button:has-text("Apply")').first

                if apply_btn and apply_btn.is_visible():
                    button_text = apply_btn.inner_text().strip().lower()
                    if "easy" not in button_text:
                        job_url = page.url
                        job_links.append(job_url)
                        print(f"[✅] Found external Apply job: {job_url}")
                    else:
                        print("[⛔] Easy Apply detected — skipped")
                else:
                    print("[❌] No Apply button")

            except Exception as e:
                print(f"[❗] Error on job {i + 1}: {e}")
                continue

        browser.close()
    return list(set(job_links))


def extract_company_site(linkedin_job_urls):
    company_sites = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        context = get_logged_in_context(browser)
        main_page = context.new_page()

        for job_url in linkedin_job_urls:
            try:
                print(f"\n[🌐] Visiting job: {job_url}")
                main_page.goto(job_url, timeout=20000)
                main_page.wait_for_timeout(3000)

                apply_btn = main_page.locator('button.jobs-apply-button:has-text("Apply")').first

                if apply_btn and apply_btn.is_visible():
                    button_text = apply_btn.inner_text().strip().lower()
                    if "easy" not in button_text:
                        with context.expect_page() as new_tab:
                            apply_btn.click()
                        time.sleep(7)  # 🔁 Delay after Apply button click

                        new_page = new_tab.value
                        new_page.wait_for_timeout(3000)

                        external_url = new_page.url
                        if "linkedin.com" not in external_url:
                            company_sites.append(external_url)
                            print(f"[🌍] External company site: {external_url}")
                        else:
                            print("[↩️] Still on LinkedIn — skipped")

                        new_page.close()
                    else:
                        print("[⛔] Easy Apply detected — skipped")
                else:
                    print("[❌] No Apply button found")

                time.sleep(1)

            except TimeoutError:
                print(f"[⏳] Timeout visiting: {job_url}")
                continue
            except Exception as e:
                print(f"[❗] Error: {e}")
                continue

        browser.close()
    return company_sites
