import json
import os

def load_config():
    with open(os.path.join("data", "config.json"), "r") as f:
        return json.load(f)

def save_applied_job(job):
    path = os.path.join("data", "applied_jobs.json")
    if not os.path.exists(path):
        with open(path, "w") as f:
            json.dump([], f)

    with open(path, "r+") as f:
        jobs = json.load(f)
        jobs.append(job)
        f.seek(0)
        json.dump(jobs, f, indent=2)
