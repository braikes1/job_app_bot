# Job Application Bot

AI-powered job application automation. Tailors your resume to every job with GPT-4o and auto-fills applications via Playwright browser automation.

## Architecture

```
job_application_bot/
├── backend/          # Python FastAPI — REST API + AI + Playwright
└── mobile/           # Flutter iOS/iPadOS app
```

---

## Quick Start

### Backend (Local Development)

**Prerequisites**: Python 3.12+, PostgreSQL

```bash
# 1. Set up environment
cd backend
cp .env.example .env
# Edit .env with your OPENAI_API_KEY and DATABASE_URL

# 2. Install dependencies
pip install -r requirements.txt

# 3. Install Playwright browsers
playwright install chromium

# 4. Run database migrations (creates tables automatically on startup)
uvicorn backend.main:app --reload --port 8000

# 5. Open Swagger UI
# http://localhost:8000/docs
```

### Flutter App (Mobile)

**Prerequisites**: Flutter 3.x SDK

```bash
cd mobile
flutter pub get
flutter run  # Requires connected iOS device or simulator
```

---

## Backend API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/register` | Create account |
| POST | `/auth/login` | Get JWT tokens |
| GET  | `/auth/me` | Current user |
| GET  | `/profiles/` | List profiles |
| POST | `/profiles/` | Create profile |
| POST | `/profiles/{id}/resume` | Upload PDF resume |
| POST | `/jobs/tailor` | AI resume tailoring |
| POST | `/jobs/apply/start` | Start automation |
| WS   | `/jobs/apply/ws/{task_id}` | Real-time status |
| GET  | `/applications/` | Application history |
| GET  | `/applications/export/csv` | Export CSV |

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `OPENAI_API_KEY` | OpenAI GPT-4o API key |
| `DATABASE_URL` | PostgreSQL connection string |
| `SECRET_KEY` | JWT signing secret |
| `S3_BUCKET_NAME` | Cloud storage bucket |
| `S3_ACCESS_KEY_ID` | S3/R2 access key |
| `S3_SECRET_ACCESS_KEY` | S3/R2 secret |
| `S3_ENDPOINT_URL` | Cloudflare R2 endpoint (if using R2) |

---

## Deployment

### Backend → Railway

```bash
npm install -g @railway/cli
railway login
railway init
railway add --database postgresql
railway up
```

Set environment variables in the Railway dashboard under **Variables**.

### Mobile → TestFlight (via Codemagic)

1. Connect your GitHub repo to [codemagic.io](https://codemagic.io)
2. Add your Apple Developer credentials in Codemagic settings
3. Push to `main` branch — build triggers automatically
4. Install the TestFlight build on your iPhone/iPad

---

## Testing

```bash
# Backend unit tests
cd job_application_bot
pytest backend/tests/ -v

# Backend with test database
pip install aiosqlite pytest-asyncio
pytest backend/tests/test_auth.py -v

# Flutter tests
cd mobile
flutter test
```

---

## Key Technologies

- **Backend**: FastAPI, SQLAlchemy (async), Alembic, Playwright
- **AI**: OpenAI GPT-4o
- **Mobile**: Flutter 3, Riverpod, GoRouter, Dio
- **Database**: PostgreSQL
- **Cloud Storage**: Cloudflare R2 / AWS S3
- **Hosting**: Railway
- **iOS CI/CD**: Codemagic
