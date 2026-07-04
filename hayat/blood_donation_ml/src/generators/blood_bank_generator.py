"""
Blood Bank Data Generator - Jordan-Specific Synthetic Blood Banks
5 verified + 10 synthetic blood banks with inventory levels.
"""

import numpy as np
import pandas as pd
import sys
import os
from datetime import datetime, timedelta

sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
from config.settings import BLOOD_GROUPS, BLOOD_GROUP_PROBABILITIES, CITY_CENTERS, RANDOM_SEED

np.random.seed(RANDOM_SEED)

REAL_BLOOD_BANKS = [
    {"name": "National Blood Bank - Amman", "city": "Amman"},
    {"name": "King Hussein Blood Bank", "city": "Amman"},
    {"name": "Zarqa Blood Bank", "city": "Zarqa"},
    {"name": "Irbid Blood Bank", "city": "Irbid"},
    {"name": "Aqaba Blood Bank", "city": "Aqaba"},
]

SYNTHETIC_NAMES = [
    "Al-Bashir Blood Center", "Jordan University Blood Bank", "South Jordan Blood Bank",
    "North Jordan Blood Center", "Central Blood Storage", "Emergency Blood Reserve",
    "Jordan Red Crescent Blood Bank", "Medical City Blood Center",
    "Al-Zarqa Regional Blood Bank", "Madaba Blood Storage",
]


def _gen_coords(city):
    if city not in CITY_CENTERS:
        city = "Other"
    lat0, lon0, r = CITY_CENTERS[city]
    angle = np.random.uniform(0, 2 * np.pi)
    radius = r * 0.3 * np.sqrt(np.random.uniform(0, 1))
    return round(lat0 + radius * np.cos(angle), 6), round(lon0 + radius * np.sin(angle), 6)


def _generate_inventory():
    """Generate current blood inventory per blood group."""
    inventory = {}
    for bg in BLOOD_GROUPS:
        # O+ and A+ have higher demand/stock
        base = np.random.randint(0, 120) if bg in ["O+", "A+"] else np.random.randint(0, 40)
        inventory[f"stock_{bg.replace('+', 'pos').replace('-', 'neg')}"] = base
    return inventory


def generate_blood_banks():
    """Generate blood bank dataset: 5 real + 10 synthetic."""
    records = []
    cities = ["Amman", "Zarqa", "Irbid", "Other", "Amman", "Aqaba", "Madaba", "Jerash", "Amman", "Zarqa"]

    for i, bb in enumerate(REAL_BLOOD_BANKS):
        city = bb["city"]
        lat, lon = _gen_coords(city)
        inv = _generate_inventory()
        record = {
            "bank_id": f"BB{str(i+1).zfill(3)}",
            "name": bb["name"],
            "city": city,
            "latitude": lat,
            "longitude": lon,
            "storage_capacity_units": int(np.random.normal(2000, 500)),
            "operating_hours": "24/7" if i < 2 else "08:00-20:00",
            "is_real": True,
            "last_updated": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        }
        record.update(inv)
        records.append(record)

    for j in range(10):
        city = cities[j]
        lat, lon = _gen_coords(city)
        inv = _generate_inventory()
        record = {
            "bank_id": f"BB{str(len(REAL_BLOOD_BANKS)+j+1).zfill(3)}",
            "name": SYNTHETIC_NAMES[j],
            "city": city,
            "latitude": lat,
            "longitude": lon,
            "storage_capacity_units": int(np.random.normal(800, 300)),
            "operating_hours": np.random.choice(["24/7", "08:00-20:00", "08:00-16:00"], p=[0.2, 0.5, 0.3]),
            "is_real": False,
            "last_updated": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        }
        record.update(inv)
        records.append(record)

    df = pd.DataFrame(records)
    df["storage_capacity_units"] = df["storage_capacity_units"].clip(100, 5000)
    return df


def main():
    print("=" * 60)
    print("🏦 GENERATING JORDAN BLOOD BANK DATA")
    print("=" * 60)
    df = generate_blood_banks()
    output_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
        "data", "raw", "blood_banks.csv"
    )
    df.to_csv(output_path, index=False)
    print(f"✅ Generated {len(df)} blood banks")
    print(f"📁 Saved to: {output_path}")
    return df


if __name__ == "__main__":
    main()
