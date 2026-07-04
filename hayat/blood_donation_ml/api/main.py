"""
Hayat ML API — FastAPI Backend
Exposes 3 ML model endpoints for the Hayat blood donation app.

Endpoints:
  POST /predict/demand              → 7-day blood demand forecast
  POST /predict/donor-score         → Donor reliability/show-rate prediction
  POST /predict/fulfillment-time    → Blood request fulfillment time estimate
  GET  /health                      → Health check + model status
  GET  /models/info                 → Model metadata and feature importances
"""

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, validator
from typing import Optional, List
import numpy as np
import os
import sys
import time
import logging

# Allow running from repo root
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)

from src.models.demand_forecasting import DemandForecastingModel
from src.models.donor_scoring import DonorScoringModel
from src.models.request_fulfillment import RequestFulfillmentModel

# ------------------------------------------------------------------
# Logging
# ------------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger("hayat_ml_api")

# ------------------------------------------------------------------
# App setup
# ------------------------------------------------------------------
app = FastAPI(
    title="🩸 Hayat ML API",
    description="Machine learning predictions for Jordan's blood donation platform.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ------------------------------------------------------------------
# Model registry (loaded at startup)
# ------------------------------------------------------------------
MODELS_DIR = os.path.join(ROOT, "models", "saved")
models = {"demand": None, "donor_scoring": None, "fulfillment": None}
model_load_status = {}


@app.on_event("startup")
async def load_models():
    global models, model_load_status
    logger.info("Loading ML models...")

    for name, cls, filename in [
        ("demand", DemandForecastingModel, "demand_forecasting.joblib"),
        ("donor_scoring", DonorScoringModel, "donor_scoring.joblib"),
        ("fulfillment", RequestFulfillmentModel, "request_fulfillment.joblib"),
    ]:
        path = os.path.join(MODELS_DIR, filename)
        if os.path.exists(path):
            try:
                m = cls()
                m.load(path)
                models[name] = m
                model_load_status[name] = {"status": "loaded", "path": path, "metrics": m.eval_metrics}
                logger.info(f"  ✅ {name} model loaded")
            except Exception as e:
                model_load_status[name] = {"status": "error", "error": str(e)}
                logger.error(f"  ❌ Failed to load {name}: {e}")
        else:
            model_load_status[name] = {"status": "not_found", "path": path}
            logger.warning(f"  ⚠️  {name} model not found at {path}. Run train_all.py first.")


# ------------------------------------------------------------------
# Request / Response Schemas
# ------------------------------------------------------------------

# --- Model 1: Demand Forecasting ---
class DemandForecastRequest(BaseModel):
    blood_group: str = Field(..., example="O+", description="Blood group (O+, A+, B+, AB+, O-, A-, B-, AB-)")
    hospital_id: str = Field(..., example="HOS001", description="Hospital identifier")
    last_7_days_units: List[float] = Field(
        default=[10, 12, 8, 15, 11, 9, 13],
        description="Units requested for each of the last 7 days"
    )
    day_of_week_today: int = Field(default=0, ge=0, le=6, description="Today's day of week (0=Mon, 6=Sun)")
    month: int = Field(default=5, ge=1, le=12, description="Current month")
    week_of_year: int = Field(default=18, ge=1, le=53, description="Current week of year")
    avg_urgency_score: float = Field(default=1.5, ge=0.0, le=3.0)


class DemandForecastResponse(BaseModel):
    blood_group: str
    hospital_id: str
    forecast: List[dict]
    total_predicted_units_7d: int
    model_metrics: dict


# --- Model 2: Donor Scoring ---
class DonorScoreRequest(BaseModel):
    donor_id: Optional[str] = Field(None, example="JD000001")
    total_donations: int = Field(..., ge=0, le=100, example=5)
    days_since_last_donation: float = Field(..., ge=0, le=730, example=60.0)
    months_since_first_donation: int = Field(..., ge=0, le=240, example=24)
    avg_response_time_hours: float = Field(..., ge=0, le=168, example=2.5)
    age: int = Field(..., ge=18, le=65, example=30)
    bmi: float = Field(default=24.0, ge=15.0, le=50.0)
    city: str = Field(default="Amman", example="Amman")
    blood_group: str = Field(..., example="O+")
    gender: str = Field(default="Male", example="Male")

    @validator("city")
    def validate_city(cls, v):
        valid = ["Amman", "Zarqa", "Irbid", "Aqaba", "Madaba", "Jerash", "Other"]
        return v if v in valid else "Other"


class DonorScoreResponse(BaseModel):
    donor_id: Optional[str]
    show_rate_probability: float
    reliability_tier: str
    is_reliable: bool
    recommendation: str


# --- Model 3: Fulfillment Time ---
class FulfillmentRequest(BaseModel):
    request_id: Optional[str] = Field(None, example="REQ000001")
    urgency: str = Field(..., example="High", description="Low / Medium / High / Critical")
    blood_group: str = Field(..., example="AB-")
    units_needed: int = Field(..., ge=1, le=50, example=6)
    stock_level: str = Field(default="Medium", description="Low / Medium / High")
    hour_of_day: int = Field(default=12, ge=0, le=23)
    day_of_week: int = Field(default=0, ge=0, le=6)
    month: int = Field(default=5, ge=1, le=12)
    is_weekend: int = Field(default=0, ge=0, le=1)
    is_holiday: int = Field(default=0, ge=0, le=1)

    @validator("urgency")
    def validate_urgency(cls, v):
        if v not in ["Low", "Medium", "High", "Critical"]:
            raise ValueError("urgency must be Low, Medium, High, or Critical")
        return v

    @validator("stock_level")
    def validate_stock(cls, v):
        if v not in ["Low", "Medium", "High"]:
            raise ValueError("stock_level must be Low, Medium, or High")
        return v


class FulfillmentResponse(BaseModel):
    request_id: Optional[str]
    estimated_fulfillment_hours: float
    confidence_low_hours: float
    confidence_high_hours: float
    fulfillment_category: str
    urgency_note: str


# ------------------------------------------------------------------
# Helper
# ------------------------------------------------------------------
BLOOD_GROUP_MAP = {"O+": 0, "A+": 1, "B+": 2, "AB+": 3, "O-": 4, "A-": 5, "B-": 6, "AB-": 7}
CITY_MAP = {"Amman": 0, "Zarqa": 1, "Irbid": 2, "Aqaba": 3, "Madaba": 4, "Jerash": 5, "Other": 6}


def _get_model(name: str):
    m = models.get(name)
    if m is None or not m.is_trained:
        raise HTTPException(
            status_code=503,
            detail=f"Model '{name}' not loaded. Run train_all.py first."
        )
    return m


# ------------------------------------------------------------------
# Routes
# ------------------------------------------------------------------

@app.get("/health", tags=["System"])
async def health():
    return {
        "status": "ok",
        "models": {
            k: v.get("status", "unknown") for k, v in model_load_status.items()
        },
        "timestamp": time.time(),
    }


@app.get("/models/info", tags=["System"])
async def models_info():
    info = {}
    for name, status in model_load_status.items():
        info[name] = status
    return info


@app.post("/predict/demand", response_model=DemandForecastResponse, tags=["Predictions"])
async def predict_demand(body: DemandForecastRequest):
    """
    **Demand Forecasting** — Predict blood unit needs for next 7 days.

    Used by hospital coordinators and blood bank managers to proactively
    prepare blood stock before shortages occur.
    """
    m = _get_model("demand")
    bg_enc = BLOOD_GROUP_MAP.get(body.blood_group, 0)

    try:
        forecast = m.predict_7day_forecast(
            blood_group_enc=bg_enc,
            hospital_id=body.hospital_id,
            last_known_units=body.last_7_days_units,
            day_of_week_start=body.day_of_week_today,
            month=body.month,
            week_of_year=body.week_of_year,
            avg_urgency_score=body.avg_urgency_score,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    total = sum(d["predicted_units_rounded"] for d in forecast)
    return DemandForecastResponse(
        blood_group=body.blood_group,
        hospital_id=body.hospital_id,
        forecast=forecast,
        total_predicted_units_7d=total,
        model_metrics=m.eval_metrics,
    )


@app.post("/predict/donor-score", response_model=DonorScoreResponse, tags=["Predictions"])
async def predict_donor_score(body: DonorScoreRequest):
    """
    **Donor Engagement Scoring** — Predict the probability a donor will show up.

    Used to prioritize which donors to contact for urgent requests.
    High-reliability donors should be contacted first.
    """
    m = _get_model("donor_scoring")

    features = {
        "total_donations": body.total_donations,
        "days_since_last_donation": body.days_since_last_donation,
        "months_since_first_donation": body.months_since_first_donation,
        "avg_response_time_hours": body.avg_response_time_hours,
        "age": body.age,
        "bmi": body.bmi,
        "city_enc": CITY_MAP.get(body.city, 6),
        "blood_group_enc": BLOOD_GROUP_MAP.get(body.blood_group, 0),
        "gender_enc": int(body.gender == "Male"),
    }

    try:
        result = m.predict(features)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    prob = result["show_rate_probability"]
    tier = result["reliability_tier"]

    rec_map = {
        "High": "🟢 Priority contact — high show-rate, contact immediately.",
        "Medium": "🟡 Moderate reliability — include in outreach, follow up.",
        "Low": "🔴 Low reliability — contact only as last resort.",
    }

    return DonorScoreResponse(
        donor_id=body.donor_id,
        show_rate_probability=prob,
        reliability_tier=tier,
        is_reliable=result["is_reliable"],
        recommendation=rec_map.get(tier, "Unknown"),
    )


@app.post("/predict/fulfillment-time", response_model=FulfillmentResponse, tags=["Predictions"])
async def predict_fulfillment(body: FulfillmentRequest):
    """
    **Request Fulfillment Time** — Estimate how many hours until a request is fulfilled.

    Used to set SLA expectations, trigger escalation for slow-filling urgent requests,
    and plan logistics.
    """
    m = _get_model("fulfillment")

    features = {
        "urgency": body.urgency,
        "blood_group": body.blood_group,
        "units_needed": body.units_needed,
        "stock_level": body.stock_level,
        "hour_of_day": body.hour_of_day,
        "day_of_week": body.day_of_week,
        "month": body.month,
        "is_weekend": body.is_weekend,
        "is_holiday": body.is_holiday,
    }

    try:
        result = m.predict(features)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    urgency_notes = {
        "Critical": "⚠️ Critical request — activate emergency protocol immediately.",
        "High": "🔴 High urgency — escalate within 2 hours if not fulfilled.",
        "Medium": "🟡 Medium urgency — monitor and escalate if exceeded 24h.",
        "Low": "🟢 Routine request — standard fulfillment process.",
    }

    return FulfillmentResponse(
        request_id=body.request_id,
        estimated_fulfillment_hours=result["estimated_fulfillment_hours"],
        confidence_low_hours=result["confidence_low_hours"],
        confidence_high_hours=result["confidence_high_hours"],
        fulfillment_category=result["fulfillment_category"],
        urgency_note=urgency_notes.get(body.urgency, ""),
    )


# ------------------------------------------------------------------
# Batch endpoints
# ------------------------------------------------------------------

@app.post("/predict/donor-score/batch", tags=["Predictions"])
async def predict_donor_score_batch(donors: List[DonorScoreRequest]):
    """Score multiple donors at once (max 500)."""
    if len(donors) > 500:
        raise HTTPException(status_code=400, detail="Max 500 donors per batch.")
    m = _get_model("donor_scoring")
    results = []
    for d in donors:
        features = {
            "total_donations": d.total_donations,
            "days_since_last_donation": d.days_since_last_donation,
            "months_since_first_donation": d.months_since_first_donation,
            "avg_response_time_hours": d.avg_response_time_hours,
            "age": d.age,
            "bmi": d.bmi,
            "city_enc": CITY_MAP.get(d.city, 6),
            "blood_group_enc": BLOOD_GROUP_MAP.get(d.blood_group, 0),
            "gender_enc": int(d.gender == "Male"),
        }
        result = m.predict(features)
        results.append({"donor_id": d.donor_id, **result})
    return {"count": len(results), "results": results}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("api.main:app", host="0.0.0.0", port=8001, reload=True)
