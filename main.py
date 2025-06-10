from core.job_search import search_linkedin_jobs, extract_company_site
from utils.file_utils import load_config
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

    config = load_config()
    keywords = config.get("keywords", "Software Engineer")
    location = config.get("location", "Remote")
    pages = config.get("scroll_pages", 2)

    # Step 1: Search LinkedIn Jobs and filter for external Apply
    print("[🔎] Searching LinkedIn for external Apply jobs...")
    external_jobs = search_linkedin_jobs(keywords, location, pages)

    if not external_jobs:
        print("[⚠️] No external apply jobs found.")
        return

    print(f"\n--- Found {len(external_jobs)} External Apply Jobs ---")
    for url in external_jobs:
        print(url)

    # Step 2: Extract final company application pages
    print("\n[🌐] Extracting final company application links...")
    final_links = extract_company_site(external_jobs)

    print(f"\n--- Final External Application Links ({len(final_links)} total) ---")
    for link in final_links:
        print(link)

    logging.info("✅ Job Application Bot Finished")

if __name__ == "__main__":
    main()
