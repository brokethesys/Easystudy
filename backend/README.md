# EasyStudy Backend (FastAPI)

Minimal file-based account backend that stores each user's config as a JSON file.

## Run locally

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --reload --port 8000
```

## Env

- `JWT_SECRET` (required in production)
- `JWT_TTL_MIN` (default `43200` = 30 days)
- `CORS_ORIGINS` (comma-separated, default `*`)

## API

- `POST /auth/register`
  - body: `{ "email": "", "password": "", "config": { ... } }`
  - response: `{ "access_token": "", "token_type": "bearer", "config": { ... } }`

- `POST /auth/login`
  - body: `{ "email": "", "password": "" }`
  - response: `{ "access_token": "", "token_type": "bearer", "config": { ... } }`

- `GET /config` (Bearer token)
  - response: `{ "config": { ... }, "updated_at": "ISO" }`

- `PUT /config` (Bearer token)
  - body: `{ "config": { ... } }`
  - response: `{ "config": { ... }, "updated_at": "ISO" }`

## Data location

- Users: `backend/data/users.json`
- Configs: `backend/data/configs/<user_id>.json`

## Notes

- This is file-based and intended for MVP/testing.
- For production, migrate to a DB and object storage.
