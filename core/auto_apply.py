from playwright.sync_api import sync_playwright
import time
import os

def run_auto_apply(job_urls, config):
    name = config["name"]
    email = config["email"]
    resume_path = os.path.abspath("data/resume.pdf")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        context = browser.new_context()
        page = context.new_page()

        for url in job_urls:
            print(f"\n🚀 Opening: {url}")
            try:
                page.goto(url, timeout=15000)

                # Wait a bit to load the page
                page.wait_for_timeout(3000)

                # === [ 1. Fill in basic input fields ] ===
                try:
                    page.fill("input[name='name'], input[id*='name']", name)
                    page.fill("input[name='email'], input[id*='email']", email)
                    print("✅ Name & email filled")
                except:
                    print("⚠️ Could not find name/email fields")

                # === [ 2. Upload resume file ] ===
                try:
                    file_input = page.query_selector("input[type='file']")
                    if file_input:
                        file_input.set_input_files(resume_path)
                        print("📎 Resume uploaded")
                except:
                    print("⚠️ Resume upload not available")

                # === [ 3. Try to click submit ] ===
                try:
                    page.click("button[type='submit'], input[type='submit']")
                    print("📨 Application submitted!")
                except:
                    print("⚠️ Submit button not found")

                time.sleep(2)

            except Exception as e:
                print(f"❌ Failed to apply on: {url}")
                print(f"Error: {e}")
                continue

        browser.close()
