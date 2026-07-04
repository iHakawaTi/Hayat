"""
Master Training Script
Generates all synthetic data, engineers features, trains 3 models, and saves them.
Run this script once to bootstrap the entire ML pipeline.

Usage:
    python train_all.py
    python train_all.py --skip-data-gen   # if data already exists
"""

import argparse
import numpy as np
import pandas as pd
import os
import sys
import time

# Fix Windows console encoding for Unicode output
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Resolve project root
ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ROOT)

from src.generators.donor_generator import MedicalDonorDataGenerator
from src.generators.hospital_generator import generate_hospitals
from src.generators.blood_bank_generator import generate_blood_banks
from src.generators.request_generator import generate_requests
from src.features.feature_engineering import (
    build_demand_features, build_donor_features, build_fulfillment_features, save_encoders
)
from src.models.demand_forecasting import DemandForecastingModel
from src.models.donor_scoring import DonorScoringModel
from src.models.request_fulfillment import RequestFulfillmentModel

RAW_DIR = os.path.join(ROOT, "data", "raw")
PROCESSED_DIR = os.path.join(ROOT, "data", "processed")
MODELS_DIR = os.path.join(ROOT, "models", "saved")
ENCODERS_DIR = os.path.join(ROOT, "models", "encoders")

os.makedirs(RAW_DIR, exist_ok=True)
os.makedirs(PROCESSED_DIR, exist_ok=True)
os.makedirs(MODELS_DIR, exist_ok=True)
os.makedirs(ENCODERS_DIR, exist_ok=True)


def banner(title: str):
    print("\n" + "=" * 65)
    print(f"  [HAYAT] {title}")
    print("=" * 65)


def step1_generate_data():
    banner("STEP 1: GENERATING SYNTHETIC DATA")
    t0 = time.time()

    # Donors (1000 samples for quick training; scale later)
    print("  [1/4] Generating donors...")
    gen = MedicalDonorDataGenerator(n_samples=1000, seed=42)
    donors_df = gen.generate()
    donors_df.to_csv(os.path.join(RAW_DIR, "donors_1k.csv"), index=False)
    print(f"        ✅ {len(donors_df)} donors saved")

    # Hospitals
    print("  [2/4] Generating hospitals...")
    hospitals_df = generate_hospitals()
    hospitals_df.to_csv(os.path.join(RAW_DIR, "hospitals.csv"), index=False)
    print(f"        ✅ {len(hospitals_df)} hospitals saved")

    # Blood banks
    print("  [3/4] Generating blood banks...")
    banks_df = generate_blood_banks()
    banks_df.to_csv(os.path.join(RAW_DIR, "blood_banks.csv"), index=False)
    print(f"        ✅ {len(banks_df)} blood banks saved")

    # Blood requests
    print("  [4/4] Generating blood requests...")
    hospital_ids = hospitals_df["hospital_id"].tolist()
    bank_ids = banks_df["bank_id"].tolist()
    requests_df = generate_requests(n=3000, hospital_ids=hospital_ids, blood_bank_ids=bank_ids)
    requests_df.to_csv(os.path.join(RAW_DIR, "blood_requests.csv"), index=False)
    print(f"        ✅ {len(requests_df)} requests saved")

    print(f"\n  ⏱️  Data generation done in {time.time()-t0:.1f}s")
    return donors_df, hospitals_df, banks_df, requests_df


def step2_feature_engineering(donors_df, requests_df):
    banner("STEP 2: FEATURE ENGINEERING")
    t0 = time.time()

    # Save encoding maps
    save_encoders(ENCODERS_DIR)

    # Model 1: Demand features
    print("  [1/3] Building demand features...")
    demand_df = build_demand_features(requests_df)
    demand_df.to_csv(os.path.join(PROCESSED_DIR, "demand_features.csv"), index=False)
    print(f"        ✅ {len(demand_df)} demand rows saved")

    # Model 2: Donor features
    print("  [2/3] Building donor features...")
    X_donor, y_donor = build_donor_features(donors_df)
    X_donor.to_csv(os.path.join(PROCESSED_DIR, "donor_features_X.csv"), index=False)
    y_donor.to_csv(os.path.join(PROCESSED_DIR, "donor_features_y.csv"), index=False)
    print(f"        ✅ {len(X_donor)} donor rows saved | class balance: {y_donor.mean():.1%} reliable")

    # Model 3: Fulfillment features
    print("  [3/3] Building fulfillment features...")
    X_fulfill, y_fulfill = build_fulfillment_features(requests_df)
    X_fulfill.to_csv(os.path.join(PROCESSED_DIR, "fulfillment_features_X.csv"), index=False)
    y_fulfill.to_csv(os.path.join(PROCESSED_DIR, "fulfillment_features_y.csv"), index=False)
    print(f"        ✅ {len(X_fulfill)} fulfillment rows saved")

    print(f"\n  ⏱️  Feature engineering done in {time.time()-t0:.1f}s")
    return demand_df, X_donor, y_donor, X_fulfill, y_fulfill


def step3_train_models(demand_df, X_donor, y_donor, X_fulfill, y_fulfill):
    banner("STEP 3: TRAINING ML MODELS")
    all_metrics = {}
    t0 = time.time()

    # ---- Model 1: Demand Forecasting ----
    print("\n  📈 Training Model 1: Demand Forecasting")
    m1 = DemandForecastingModel()
    m1_metrics = m1.train(demand_df)
    m1.save(os.path.join(MODELS_DIR, "demand_forecasting.joblib"))
    all_metrics["demand_forecasting"] = m1_metrics

    # ---- Model 2: Donor Scoring ----
    print("\n  👤 Training Model 2: Donor Scoring")
    m2 = DonorScoringModel()
    m2_metrics = m2.train(X_donor, y_donor)
    m2.save(os.path.join(MODELS_DIR, "donor_scoring.joblib"))
    all_metrics["donor_scoring"] = m2_metrics

    # ---- Model 3: Fulfillment Time ----
    print("\n  ⏱️  Training Model 3: Request Fulfillment Time")
    m3 = RequestFulfillmentModel()
    m3_metrics = m3.train(X_fulfill, y_fulfill)
    m3.save(os.path.join(MODELS_DIR, "request_fulfillment.joblib"))
    all_metrics["request_fulfillment"] = m3_metrics

    print(f"\n  ⏱️  Model training done in {time.time()-t0:.1f}s")
    return all_metrics, m1, m2, m3


def step4_validation(m1, m2, m3):
    banner("STEP 4: VALIDATION — SAMPLE PREDICTIONS")

    print("\n  📈 Demand Forecast (O+ blood, next 7 days):")
    forecast = m1.predict_7day_forecast(
        blood_group_enc=0, hospital_id="HOS001",
        last_known_units=[15, 12, 18, 10, 20, 14, 11],
        day_of_week_start=0, month=5, week_of_year=18
    )
    for day in forecast:
        print(f"    Day {day['day_offset']}: {day['predicted_units_rounded']} units")

    print("\n  👤 Donor Score (experienced donor):")
    score = m2.predict({
        "total_donations": 8, "days_since_last_donation": 70,
        "months_since_first_donation": 36, "avg_response_time_hours": 1.5,
        "age": 32, "bmi": 24.0, "city_enc": 0, "blood_group_enc": 0, "gender_enc": 1
    })
    print(f"    → {score}")

    print("\n  ⏱️  Fulfillment Time (Critical AB-, 8 units, low stock):")
    est = m3.predict({
        "urgency": "Critical", "blood_group": "AB-",
        "units_needed": 8, "stock_level": "Low",
        "hour_of_day": 3, "day_of_week": 5,
        "month": 5, "is_weekend": 1, "is_holiday": 0,
    })
    print(f"    → {est}")


def main():
    parser = argparse.ArgumentParser(description="Train all Hayat ML models")
    parser.add_argument("--skip-data-gen", action="store_true",
                        help="Skip data generation if CSVs already exist")
    args = parser.parse_args()

    banner("HAYAT BLOOD DONATION ML — FULL PIPELINE")

    if args.skip_data_gen:
        print("\n  📂 Loading existing raw data...")
        donors_df = pd.read_csv(os.path.join(RAW_DIR, "donors_1k.csv"))
        hospitals_df = pd.read_csv(os.path.join(RAW_DIR, "hospitals.csv"))
        banks_df = pd.read_csv(os.path.join(RAW_DIR, "blood_banks.csv"))
        requests_df = pd.read_csv(os.path.join(RAW_DIR, "blood_requests.csv"))
        print(f"  ✅ Loaded: {len(donors_df)} donors, {len(requests_df)} requests")
    else:
        donors_df, hospitals_df, banks_df, requests_df = step1_generate_data()

    demand_df, X_donor, y_donor, X_fulfill, y_fulfill = step2_feature_engineering(donors_df, requests_df)
    all_metrics, m1, m2, m3 = step3_train_models(demand_df, X_donor, y_donor, X_fulfill, y_fulfill)
    step4_validation(m1, m2, m3)

    banner("✅ PIPELINE COMPLETE")
    print("\n  Model Evaluation Summary:")
    for model_name, metrics in all_metrics.items():
        print(f"\n  [{model_name}]")
        for k, v in metrics.items():
            print(f"    {k}: {v:.4f}")

    print(f"\n  📁 Models saved in: {MODELS_DIR}")
    print(f"  🚀 Start API:  cd blood_donation_ml && uvicorn api.main:app --reload --port 8001")


if __name__ == "__main__":
    main()
