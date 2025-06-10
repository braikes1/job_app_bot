from playwright.sync_api import Page
import time

def detect_and_process_first_job(page: Page):
    print("[🔍] Detecting first job card...")
    job_cards = page.locator("div.job-card-container--clickable")
    total = job_cards.count()
    print(f"[📋] Job cards detected: {total}")

    if total == 0:
        print("[❌] No job cards found.")
        return

    try:
        job_card = job_cards.nth(0)
        job_card.scroll_into_view_if_needed()
        job_card.click(force=True)
        time.sleep(4)

        easy_apply_btn = page.locator("section.jobs-details__main-content button:has-text('Easy Apply')").first
        if easy_apply_btn and easy_apply_btn.is_visible():
            print("[⏭️] First job is Easy Apply — skipping...")
            return

        apply_button = page.locator("button:has-text('Apply')").first
        if apply_button and apply_button.is_visible():
            print("[🚀] Clicking external Apply...")
            apply_button.click()
            time.sleep(6)
        else:
            print("[❌] No Apply button found.")
    except Exception as e:
        print(f"[⚠️] Error clicking first job: {e}")


def scroll_and_detect_jobs(page: Page):
    print("[🔁] Starting scroll detection logic...")
    seen_jobs = 0
    scroll_attempts = 0
    max_scroll_attempts = 5

    while scroll_attempts < max_scroll_attempts:
        job_cards = page.locator("div.job-card-container--clickable")
        total = job_cards.count()
        print(f"[📋] Job cards found: {total} (seen: {seen_jobs})")

        if total == seen_jobs:
            print("[↕️] Scrolling down...")
            page.mouse.wheel(0, 4000)
            scroll_attempts += 1
            time.sleep(3)
            continue

        seen_jobs = total
        scroll_attempts = 0


def handle_job_cards_and_apply(page: Page):
    print("[⚙️] Handling job cards...")

    job_cards = page.locator("div.job-card-container--clickable")
    total_cards = job_cards.count()

    print(f"[📋] Total job cards found: {total_cards}")

    for i in range(total_cards):
        try:
            job_card = job_cards.nth(i)
            job_card.scroll_into_view_if_needed()
            print(f"[🖱️] Clicking job card {i + 1}...")
            job_card.click(force=True)
            time.sleep(4)

            easy_apply_btn = page.locator("section.jobs-details__main-content button:has-text('Easy Apply')").first
            if easy_apply_btn and easy_apply_btn.is_visible():
                print(f"[⏭️] Job {i + 1} is Easy Apply — skipping...")
                continue

            apply_button = page.locator("button:has-text('Apply')").first
            if apply_button and apply_button.is_visible():
                print(f"[🚀] Clicking external Apply on job {i + 1}...")
                apply_button.click()
                time.sleep(6)
            else:
                print(f"[❌] No Apply button visible for job {i + 1} — skipping...")

        except Exception as e:
            print(f"[⚠️] Error processing job {i + 1}: {e}")
            continue

    print("[✅] Finished processing job cards.")
