from platforms.linkedin import search_linkedin_jobs, extract_company_site

def run_job_search(config):
    print("[🔍] Running LinkedIn job search...")

    job_links = search_linkedin_jobs(
        config.get("keywords", ""),
        config.get("location", "Remote"),
        pages=2,
        custom_url=config.get("custom_url")
    ) or []

    print(f"[🔗] Found {len(job_links)} job post links")

    if not job_links:
        print("[⚠️] No job links found. Skipping external company check.")
        return []

    company_sites = extract_company_site(job_links) or []
    print(f"[🌐] Found {len(company_sites)} external company application links")

    # Optional: Show all collected URLs
    for site in company_sites:
        print(f"[🌍] {site}")

    return company_sites
