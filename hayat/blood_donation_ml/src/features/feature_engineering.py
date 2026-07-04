"""
Feature Engineering Pipeline
Transforms raw donor, request, and hospital data into ML-ready features.
"""

import numpy as np
import pandas as pd
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.model_selection import train_test_split
import sys
import os
import joblib

sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
from config.settings import BLOOD_GROUPS, JORDAN_CITIES, RANDOM_SEED


# ------------------------------------------------------------------
# ENCODING MAPS (consistent across train and serve)
# ------------------------------------------------------------------
BLOOD_GROUP_MAP = {bg: i for i, bg in enumerate(BLOOD_GROUPS)}
CITY_MAP = {city: i for i, city in enumerate(JORDAN_CITIES + ["Other"])}
URGENCY_MAP = {"Low": 0, "Medium": 1, "High": 2, "Critical": 3}
STOCK_MAP = {"Low": 0, "Medium": 1, "High": 2}


# ------------------------------------------------------------------
# MODEL 1: DEMAND FORECASTING FEATURES
# ------------------------------------------------------------------
def build_demand_features(requests_df: pd.DataFrame) -> pd.DataFrame:
    """
    Aggregate blood requests into daily demand features for forecasting.
    Output: one row per (date, blood_group, hospital_id)
    """
    df = requests_df.copy()
    df["request_date"] = pd.to_datetime(df["request_time"]).dt.date

    agg = df.groupby(["request_date", "blood_group", "hospital_id"]).agg(
        units_requested=("units_needed", "sum"),
        request_count=("request_id", "count"),
        avg_urgency_score=("urgency", lambda x: x.map(URGENCY_MAP).mean()),
    ).reset_index()

    agg["request_date"] = pd.to_datetime(agg["request_date"])
    agg["day_of_week"] = agg["request_date"].dt.dayofweek
    agg["month"] = agg["request_date"].dt.month
    agg["week_of_year"] = agg["request_date"].dt.isocalendar().week.astype(int)
    agg["blood_group_enc"] = agg["blood_group"].map(BLOOD_GROUP_MAP)

    # Lag features (simulate: for each group, lag by 1 and 7 days)
    agg = agg.sort_values(["blood_group", "hospital_id", "request_date"])
    agg["lag_1_units"] = agg.groupby(["blood_group", "hospital_id"])["units_requested"].shift(1).fillna(0)
    agg["lag_7_units"] = agg.groupby(["blood_group", "hospital_id"])["units_requested"].shift(7).fillna(0)
    agg["rolling_7d_mean"] = (
        agg.groupby(["blood_group", "hospital_id"])["units_requested"]
        .transform(lambda x: x.shift(1).rolling(7, min_periods=1).mean())
        .fillna(0)
    )

    return agg.dropna(subset=["blood_group_enc"])


# ------------------------------------------------------------------
# MODEL 2: DONOR SHOW-RATE FEATURES
# ------------------------------------------------------------------
def build_donor_features(donors_df: pd.DataFrame) -> tuple[pd.DataFrame, pd.Series]:
    """
    Prepare donor features for show-rate binary classification.
    Target: show_rate binarized at 0.7 threshold → 1 = reliable.
    """
    df = donors_df.copy()

    feature_cols = [
        "total_donations", "days_since_last_donation", "months_since_first_donation",
        "avg_response_time_hours", "age", "bmi",
    ]

    df["city_enc"] = df["city"].map(CITY_MAP).fillna(len(JORDAN_CITIES))
    df["blood_group_enc"] = df["blood_group"].map(BLOOD_GROUP_MAP).fillna(0)
    df["gender_enc"] = (df["gender"] == "Male").astype(int)

    feature_cols += ["city_enc", "blood_group_enc", "gender_enc"]

    # Binary target: show_rate >= 0.7 → reliable donor
    y = (df["show_rate"] >= 0.7).astype(int)

    X = df[feature_cols].fillna(0)
    return X, y


# ------------------------------------------------------------------
# MODEL 3: REQUEST FULFILLMENT TIME FEATURES
# ------------------------------------------------------------------
def build_fulfillment_features(requests_df: pd.DataFrame) -> tuple[pd.DataFrame, pd.Series]:
    """
    Prepare features for request fulfillment time regression.
    Target: time_to_fulfill_hours (continuous, fulfilled requests only).
    """
    df = requests_df.copy()
    df = df[df["is_fulfilled"] == 1].dropna(subset=["time_to_fulfill_hours"])

    df["urgency_enc"] = df["urgency"].map(URGENCY_MAP)
    df["blood_group_enc"] = df["blood_group"].map(BLOOD_GROUP_MAP).fillna(0)
    df["stock_level_enc"] = df["stock_level_at_request"].map(STOCK_MAP).fillna(1)
    df["is_rare_blood"] = df["blood_group"].isin(["AB-", "B-", "O-"]).astype(int)

    feature_cols = [
        "urgency_enc", "blood_group_enc", "units_needed", "stock_level_enc",
        "hour_of_day", "day_of_week", "month", "is_weekend", "is_holiday",
        "is_rare_blood",
    ]

    X = df[feature_cols].fillna(0)
    y = np.log1p(df["time_to_fulfill_hours"])  # log-transform for regression
    return X, y


def save_encoders(output_dir: str):
    """Persist encoding maps as joblib for serving."""
    os.makedirs(output_dir, exist_ok=True)
    joblib.dump(BLOOD_GROUP_MAP, os.path.join(output_dir, "blood_group_map.joblib"))
    joblib.dump(CITY_MAP, os.path.join(output_dir, "city_map.joblib"))
    joblib.dump(URGENCY_MAP, os.path.join(output_dir, "urgency_map.joblib"))
    joblib.dump(STOCK_MAP, os.path.join(output_dir, "stock_map.joblib"))
    print("✅ Encoding maps saved.")


if __name__ == "__main__":
    save_encoders(os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
        "models", "encoders"
    ))
