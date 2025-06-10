from playwright.sync_api import sync_playwright
from core.job_search import get_logged_in_context, get_external_apply_jobs, visit_and_extract_apply_links
import logging
import os

# Setup logging
logging.basicConfig(
    filename=os.path.join("logs", "run.log"),
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

def main():
    logging.info("🚀 Job Application Bot Started")
    print("[🚀] Job Application Bot Starting...\n")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False, slow_mo=250)
        context = get_logged_in_context(browser)
        page = context.new_page()

        print("[🔍] Searching LinkedIn for jobs with external Apply buttons...\n")
        job_urls = get_external_apply_jobs(page)

        if not job_urls:
            print("[⚠️] No valid external apply jobs found.")
            return

        print(f"\n--- Found {len(job_urls)} Jobs ---")
        for url in job_urls:
            print(url)

        print("\n[🌐] Visiting each job page to extract external company links...\n")
        final_links = visit_and_extract_apply_links(context, job_urls)

        print(f"\n--- Final External Application Links ({len(final_links)} total) ---")
        for link in final_links:
            print(link)

        logging.info("✅ Job Application Bot Finished")
        browser.close()

if __name__ == "__main__":
    main()
