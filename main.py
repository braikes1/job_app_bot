from core.job_search import run_job_search
from core.auto_apply import run_auto_apply
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
    logging.info("Job Application Bot Started")

    config = load_config()

    # ✅ Run search and fallback to [] if something fails
    job_listings = run_job_search(config) or []

    print(f"\n--- Found {len(job_listings)} Jobs ---")
    for job in job_listings:
        print(job)

    # ✅ Proceed to apply if jobs exist
    if job_listings:
        run_auto_apply(job_listings, config)
    else:
        print("[⚠️] No jobs found to apply to.")

    logging.info("Job Application Bot Finished")

if __name__ == "__main__":
    main()
