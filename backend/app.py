from __future__ import annotations

import json
import os
import time
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, Optional

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr, Field

DATA_DIR = Path(__file__).parent / "data"
USERS_FILE = DATA_DIR / "users.json"
CONFIG_DIR = DATA_DIR / "configs"

DATA_DIR.mkdir(parents=True, exist_ok=True)
CONFIG_DIR.mkdir(parents=True, exist_ok=True)

JWT_SECRET = os.getenv("JWT_SECRET", "dev-secret-change-me")
JWT_ALG = "HS256"
JWT_TTL_MIN = int(os.getenv("JWT_TTL_MIN", "43200"))  # 30 days

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

app = FastAPI(title="EasyStudy Account Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS", "*").split(","),
    allow_credentials=True,
    allow_methods=["*"] ,
    allow_headers=["*"] ,
)


@dataclass
class User:
    id: str
    email: str
    password_hash: str
    created_at: str


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    config: Optional[Dict[str, Any]] = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    config: Optional[Dict[str, Any]] = None


class ConfigPayload(BaseModel):
    config: Dict[str, Any]


class HealthResponse(BaseModel):
    status: str
    time: int


class ConfigResponse(BaseModel):
    config: Dict[str, Any]
    updated_at: str


# -----------------------
# Storage helpers
# -----------------------

def _read_json(path: Path) -> Any:
    if not path.exists():
        return None
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def _write_json(path: Path, data: Any) -> None:
    tmp = path.with_suffix(".tmp")
    with tmp.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    tmp.replace(path)


def _load_users() -> Dict[str, Dict[str, Any]]:
    data = _read_json(USERS_FILE)
    if data is None:
        return {}
    if not isinstance(data, dict):
        return {}
    return data


def _save_users(users: Dict[str, Dict[str, Any]]) -> None:
    _write_json(USERS_FILE, users)


def _find_user_by_email(users: Dict[str, Dict[str, Any]], email: str) -> Optional[User]:
    for raw in users.values():
        if raw.get("email") == email:
            return User(**raw)
    return None


def _get_config_path(user_id: str) -> Path:
    return CONFIG_DIR / f"{user_id}.json"


# -----------------------
# Auth helpers
# -----------------------

def _hash_password(password: str) -> str:
    return pwd_context.hash(password)


def _verify_password(password: str, password_hash: str) -> bool:
    return pwd_context.verify(password, password_hash)


def _create_token(user_id: str, email: str) -> str:
    now = datetime.utcnow()
    payload = {
        "sub": user_id,
        "email": email,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=JWT_TTL_MIN)).timestamp()),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALG)


def _decode_token(token: str) -> Dict[str, Any]:
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALG])
    except JWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        ) from exc


def _current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> User:
    payload = _decode_token(credentials.credentials)
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token payload")

    users = _load_users()
    raw = users.get(user_id)
    if not raw:
        raise HTTPException(status_code=401, detail="User not found")
    return User(**raw)


# -----------------------
# Routes
# -----------------------

@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(status="ok", time=int(time.time()))


@app.post("/auth/register", response_model=AuthResponse)
def register(payload: RegisterRequest) -> AuthResponse:
    users = _load_users()
    existing = _find_user_by_email(users, payload.email)
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    user_id = str(uuid.uuid4())
    user = User(
        id=user_id,
        email=payload.email,
        password_hash=_hash_password(payload.password),
        created_at=datetime.utcnow().isoformat(),
    )

    users[user_id] = user.__dict__
    _save_users(users)

    if payload.config is not None:
        _write_json(_get_config_path(user_id), {
            "config": payload.config,
            "updated_at": datetime.utcnow().isoformat(),
        })

    token = _create_token(user_id, user.email)
    return AuthResponse(access_token=token, config=payload.config)


@app.post("/auth/login", response_model=AuthResponse)
def login(payload: LoginRequest) -> AuthResponse:
    users = _load_users()
    user = _find_user_by_email(users, payload.email)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not _verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = _create_token(user.id, user.email)
    config_path = _get_config_path(user.id)
    config_data = _read_json(config_path)
    config = None
    if isinstance(config_data, dict) and "config" in config_data:
        config = config_data.get("config")

    return AuthResponse(access_token=token, config=config)


@app.get("/config", response_model=ConfigResponse)
def get_config(user: User = Depends(_current_user)) -> ConfigResponse:
    config_path = _get_config_path(user.id)
    data = _read_json(config_path)
    if not isinstance(data, dict) or "config" not in data:
        raise HTTPException(status_code=404, detail="Config not found")
    return ConfigResponse(config=data["config"], updated_at=data.get("updated_at", ""))


@app.put("/config", response_model=ConfigResponse)
def put_config(payload: ConfigPayload, user: User = Depends(_current_user)) -> ConfigResponse:
    data = {
        "config": payload.config,
        "updated_at": datetime.utcnow().isoformat(),
    }
    _write_json(_get_config_path(user.id), data)
    return ConfigResponse(config=payload.config, updated_at=data["updated_at"])
