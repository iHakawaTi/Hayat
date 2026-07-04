"""
Hospital Data Generator - Jordan-Specific Synthetic Hospital Data
Based on MoH structure with real + synthetic hospitals.
"""

import numpy as np
import pandas as pd
import sys
import os
from datetime import datetime

sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
from config.settings import JORDAN_CITIES, CITY_CENTERS, RANDOM_SEED

np.random.seed(RANDOM_SEED)

REAL_HOSPITALS = [
    {"name": "Jordan University Hospital", "city": "Amman", "type": "University"},
    {"name": "King Hussein Medical Center", "city": "Amman", "type": "Military"},
    {"name": "Al-Bashir Hospital", "city": "Amman", "type": "Government"},
    {"name": "Prince Hamzah Hospital", "city": "Amman", "type": "Government"},
    {"name": "Queen Alia Military Hospital", "city": "Amman", "type": "Military"},
    {"name": "Al-Zarqa Government Hospital", "city": "Zarqa", "type": "Government"},
    {"name": "Irbid Government Hospital", "city": "Irbid", "type": "Government"},
    {"name": "Aqaba Government Hospital", "city": "Aqaba", "type": "Government"},
    {"name": "Madaba Hospital", "city": "Madaba", "type": "Government"},
    {"name": "Jerash Government Hospital", "city": "Jerash", "type": "Government"},
]

HOSPITAL_TYPES = ["Government", "Private", "University", "Military", "Specialty"]
TYPE_PROBABILITIES = [0.45, 0.30, 0.10, 0.10, 0.05]

SYNTHETIC_NAMES = [
    "Al-Noor Medical Center", "Al-Shifa Hospital", "Jordan Medical Complex",
    "Al-Amal Hospital", "Al-Hayat Medical Center", "Al-Rahma Hospital",
    "Al-Wafa Medical Center", "Jordan National Hospital", "Al-Salam Hospital",
    "Al-Hilal Medical Center", "Al-Jazeera Hospital",
]


def _gen_coords(city):
    if city not in CITY_CENTERS:
        city = "Other"
    lat0, lon0, r = CITY_CENTERS[city]
    angle = np.random.uniform(0, 2 * np.pi)
    radius = r * 0.5 * np.sqrt(np.random.uniform(0, 1))
    return round(lat0 + radius * np.cos(angle), 6), round(lon0 + radius * np.sin(angle), 6)


def generate_hospitals(n_synthetic=11):
    """Generate hospital dataset: 10 real + n_synthetic synthetic."""
    records = []

    for i, h in enumerate(REAL_HOSPITALS):
        city = h["city"]
        lat, lon = _gen_coords(city)
        records.append({
            "hospital_id": f"HOS{str(i+1).zfill(3)}",
            "name": h["name"],
            "city": city,
            "type": h["type"],
            "latitude": lat,
            "longitude": lon,
            "bed_capacity": int(np.random.normal(400, 100)),
            "icu_beds": int(np.random.normal(30, 10)),
            "has_blood_bank": True,
            "daily_blood_units_capacity": int(np.random.normal(50, 15)),
            "emergency_level": np.random.choice(["Level 1", "Level 2", "Level 3"], p=[0.3, 0.5, 0.2]),
            "is_real": True,
        })

    for j in range(n_synthetic):
        city = np.random.choice(JORDAN_CITIES, p=[0.448, 0.149, 0.111, 0.019, 0.016, 0.005, 0.252])
        lat, lon = _gen_coords(city)
        htype = np.random.choice(HOSPITAL_TYPES, p=TYPE_PROBABILITIES)
        records.append({
            "hospital_id": f"HOS{str(len(REAL_HOSPITALS)+j+1).zfill(3)}",
            "name": SYNTHETIC_NAMES[j % len(SYNTHETIC_NAMES)],
            "city": city,
            "type": htype,
            "latitude": lat,
            "longitude": lon,
            "bed_capacity": int(np.random.normal(200, 80)),
            "icu_beds": int(np.random.normal(15, 7)),
            "has_blood_bank": np.random.random() < 0.6,
            "daily_blood_units_capacity": int(np.random.normal(25, 10)),
            "emergency_level": np.random.choice(["Level 1", "Level 2", "Level 3"], p=[0.15, 0.50, 0.35]),
            "is_real": False,
        })

    df = pd.DataFrame(records)
    df["bed_capacity"] = df["bed_capacity"].clip(50, 1200)
    df["icu_beds"] = df["icu_beds"].clip(5, 100)
    df["daily_blood_units_capacity"] = df["daily_blood_units_capacity"].clip(10, 150)
    return df


def main():
    print("=" * 60)
    print("🏥 GENERATING JORDAN HOSPITAL DATA")
    print("=" * 60)
    df = generate_hospitals()
    output_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
        "data", "raw", "hospitals.csv"
    )
    df.to_csv(output_path, index=False)
    print(f"✅ Generated {len(df)} hospitals")
    print(f"📁 Saved to: {output_path}")
    print(df[["hospital_id", "name", "city", "type"]].to_string())
    return df


if __name__ == "__main__":
    main()
