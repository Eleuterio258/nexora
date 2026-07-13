from contextlib import asynccontextmanager
import json
import logging
import os
import time
from uuid import uuid4

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import select
from slowapi.errors import RateLimitExceeded

from app.bootstrap import seed_data
from app.limiter import limiter
from app.config import settings
from app.database import Base, SessionLocal, engine
from app.routers import audit, biometric, fingerprint, liveness, monitoring


logger = logging.getLogger("faceclock.api")
if not logger.handlers:
    logging.basicConfig(level=logging.INFO, format="%(message)s")


@asynccontextmanager
async def lifespan(app_instance: FastAPI):
    logger.info("FaceClock API starting up (version=%s)", app_instance.version)
    logger.info("Environment: %s", settings.environment)
    logger.info("Database: %s", settings.database_url)
    logger.info("Docs: %s", settings.docs_url)
    settings.assert_production_secrets()
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("Database schema ensured.")
    except Exception as exc:
        logger.error("Failed to ensure database schema: %s", exc)
    if settings.seed_data_on_startup:
        logger.info("Seeding demo data...")
        db = SessionLocal()
        try:
            seed_data(db)
            logger.info("Seed data completed.")
        except Exception as exc:
            logger.error("Seed data failed: %s", exc)
        finally:
            db.close()
    logger.info("FaceClock API ready.")
    yield
    logger.info("FaceClock API shutting down.")


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Gateway stateless de captura e validacao biométrica de assiduidade. Apenas templates biométricos (face/digital) são persistidos localmente; todo o resto é delegado ao Nexora ERP.",
    docs_url=settings.docs_url,
    openapi_url=settings.openapi_url,
    lifespan=lifespan,
)
app.state.limiter = limiter
app.state.metrics = {
    "http_requests_total": 0,
    "http_requests_by_path": {},
    "http_errors_total": 0,
    "http_request_duration_ms_sum": 0.0,
    "http_request_durations_ms": [],  # For percentile calculation
}

# CORS middleware
cors_origins = os.getenv("CORS_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request body size limit (10MB)
app.state.max_request_body_size = int(os.getenv("MAX_REQUEST_BODY_SIZE_BYTES", "10485760"))

app.include_router(biometric.router, prefix="/api/v1")
app.include_router(liveness.router, prefix="/api/v1")
app.include_router(fingerprint.router, prefix="/api/v1")
app.include_router(audit.router, prefix="/api/v1")
app.include_router(monitoring.router)


@app.exception_handler(RateLimitExceeded)
async def rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded):
    from fastapi.responses import JSONResponse
    return JSONResponse(
        status_code=429,
        content={
            "detail": "Limite de requisicoes excedido. Tente novamente mais tarde.",
            "retry_after": str(exc.detail),
        },
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    from fastapi.responses import JSONResponse
    logger.exception(
        "Unhandled %s on %s %s: %s",
        type(exc).__name__,
        request.method,
        request.url.path,
        exc,
    )
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Erro interno do servidor. Consulte os logs para detalhes.",
            "error_type": type(exc).__name__,
        },
    )


@app.get("/health", tags=["Health"])
def healthcheck() -> dict[str, str]:
    return {"status": "ok", "version": app.version}


@app.get("/ready", tags=["Health"])
def readiness_probe() -> JSONResponse:
    """Verifica se a aplicacao e dependencias estao prontas."""
    checks: dict = {"database": "unknown", "status": "checking"}
    try:
        db = SessionLocal()
        db.execute(select(1))
        db.close()
        checks["database"] = "ok"
    except Exception as exc:
        checks["database"] = f"error: {str(exc)}"
        checks["status"] = "unavailable"

    status_code = 200 if checks["status"] != "unavailable" else 503
    return JSONResponse(status_code=status_code, content=checks)


@app.middleware("http")
async def structured_logging_middleware(request: Request, call_next):
    # Check body size
    content_length = request.headers.get("content-length")
    if content_length and int(content_length) > app.state.max_request_body_size:
        from fastapi.responses import JSONResponse
        return JSONResponse(status_code=413, content={"detail": "Payload too large."})

    request_id = request.headers.get("x-request-id", str(uuid4()))
    start = time.perf_counter()
    response = await call_next(request)
    duration_ms = round((time.perf_counter() - start) * 1000, 2)
    app.state.metrics["http_requests_total"] += 1
    app.state.metrics["http_request_duration_ms_sum"] += duration_ms
    app.state.metrics["http_request_durations_ms"].append(duration_ms)
    # Keep only last 10000 durations for memory efficiency
    if len(app.state.metrics["http_request_durations_ms"]) > 10000:
        app.state.metrics["http_request_durations_ms"] = app.state.metrics["http_request_durations_ms"][-10000:]
    app.state.metrics["http_requests_by_path"][request.url.path] = (
        app.state.metrics["http_requests_by_path"].get(request.url.path, 0) + 1
    )
    if response.status_code >= 400:
        app.state.metrics["http_errors_total"] += 1
    response.headers["x-request-id"] = request_id
    logger.info(
        json.dumps(
            {
                "event": "http_request",
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
                "duration_ms": duration_ms,
            }
        )
    )
    return response
