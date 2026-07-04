"""
Blood Request Data Generator - Synthetic blood requests with urgency levels,
hospital assignments, and time patterns.
"""

import numpy as np
import pandas as pd
import sys
import os
from datetime import datetime, timedelta

sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
from config.settings import (
    BLOOD_GROUPS, BLOOD_GROUP_PROBABILITIES, URGENCY_LEVELS, URGENCY_PROBABILITIES,
    UNITS_BY_URGENCY, REQUEST_REASONS, REQUEST_REASON_PROBABILITIES,
    BLOOD_COMPONENTS, COMPONENT_PROBABILITIES, RANDOM_SEED
)

np.random.seed(RANDOM_SEED)

# Jordanian public holidays (approximate)
JORDAN_HOLIDAYS_2024_2025 = [
    "2024-01-01", "2024-05-01", "2024-05-15", "2024-06-10", "2024-06-16",
    "2024-07-17", "2024-11-14", "2024-12-25",
    "2025-01-01", "2025-04-10", "2025-05-01", "2025-06-06", "2025-07-07",
    "2025-11-14", "2025-12-25",
]
HOLIDAY_SET = set(JORDAN_HOLIDAYS_2024_2025)


def _is_holiday(date: datetime) -> bool:
    return date.strftime("%Y-%m-%d") in HOLIDAY_SET


def _fulfillment_time(urgency: str, blood_group: str, units_needed: int, stock_level: str) -> float:
    """Simulate fulfillment time in hours based on urgency and context."""
    base = {"Critical": 2.0, "High": 8.0, "Medium": 24.0, "Low": 72.0}[urgency]
    rare_penalty = 1.5 if blood_group in ["AB-", "B-", "O-"] else 1.0
    units_penalty = 1.0 + (units_needed / 10.0)
    stock_penalty = {"Low": 2.0, "Medium": 1.2, "High": 0.8}[stock_level]
    noise = np.random.normal(1.0, 0.2)
    hours = base * rare_penalty * units_penalty * stock_penalty * noise
    return round(max(0.5, hours), 2)


def generate_requests(n=3000, hospital_ids=None, blood_bank_ids=None):
    """Generate synthetic blood request records."""
    if hospital_ids is None:
        hospital_ids = [f"HOS{str(i).zfill(3)}" for i in range(1, 22)]
    if blood_bank_ids is None:
        blood_bank_ids = [f"BB{str(i).zfill(3)}" for i in range(1, 16)]

    # Date range: past 12 months
    end_date = datetime.now()
    start_date = end_date - timedelta(days=365)

    records = []
    for i in range(n):
        urgency = np.random.choice(URGENCY_LEVELS, p=URGENCY_PROBABILITIES)
        blood_group = np.random.choice(BLOOD_GROUPS, p=BLOOD_GROUP_PROBABILITIES)
        units_min, units_max = UNITS_BY_URGENCY[urgency]
        units_needed = int(np.random.randint(units_min, units_max + 1))
        component = np.random.choice(BLOOD_COMPONENTS, p=COMPONENT_PROBABILITIES)
        reason = np.random.choice(REQUEST_REASONS, p=REQUEST_REASON_PROBABILITIES)
        hospital_id = np.random.choice(hospital_ids)
        assigned_blood_bank = np.random.choice(blood_bank_ids)
        stock_level = np.random.choice(["Low", "Medium", "High"], p=[0.2, 0.5, 0.3])

        # Random timestamp within range
        random_seconds = np.random.randint(0, int((end_date - start_date).total_seconds()))
        request_time = start_date + timedelta(seconds=int(random_seconds))

        fulfill_hours = _fulfillment_time(urgency, blood_group, units_needed, stock_level)
        fulfilled = np.random.random() < (0.98 if urgency == "Critical" else 0.85)

        records.append({
            "request_id": f"REQ{str(i+1).zfill(6)}",
            "hospital_id": hospital_id,
            "blood_bank_id": assigned_blood_bank,
            "blood_group": blood_group,
            "component": component,
            "units_needed": units_needed,
            "urgency": urgency,
            "reason": reason,
            "stock_level_at_request": stock_level,
            "request_time": request_time.strftime("%Y-%m-%d %H:%M:%S"),
            "hour_of_day": request_time.hour,
            "day_of_week": request_time.weekday(),  # 0=Mon, 6=Sun
            "month": request_time.month,
            "year": request_time.year,
            "is_weekend": int(request_time.weekday() >= 4),
            "is_holiday": int(_is_holiday(request_time)),
            "time_to_fulfill_hours": fulfill_hours if fulfilled else None,
            "is_fulfilled": int(fulfilled),
            "units_fulfilled": units_needed if fulfilled else int(units_needed * np.random.uniform(0.3, 0.9)),
        })

    df = pd.DataFrame(records)
    df["request_time"] = pd.to_datetime(df["request_time"])
    return df


def main():
    print("=" * 60)
    print("📋 GENERATING BLOOD REQUEST DATA")
    print("=" * 60)
    df = generate_requests(n=3000)
    output_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
        "data", "raw", "blood_requests.csv"
    )
    df.to_csv(output_path, index=False)
    print(f"✅ Generated {len(df)} blood requests")
    print(f"📁 Saved to: {output_path}")
    print(f"\n📊 Urgency Distribution:\n{df['urgency'].value_counts()}")
    print(f"\n🩸 Blood Group Distribution:\n{df['blood_group'].value_counts()}")
    return df


if __name__ == "__main__":
    main()
