"""
data_loader.py
Utility for loading raw or processed data from disk or Supabase.
"""

import pandas as pd
import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

RAW_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "data", "raw"
)
PROCESSED_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "data", "processed"
)


def load_raw(filename: str) -> pd.DataFrame:
    path = os.path.join(RAW_DIR, filename)
    if not os.path.exists(path):
        raise FileNotFoundError(f"Raw data not found: {path}. Run train_all.py first.")
    return pd.read_csv(path)


def load_processed(filename: str) -> pd.DataFrame:
    path = os.path.join(PROCESSED_DIR, filename)
    if not os.path.exists(path):
        raise FileNotFoundError(f"Processed data not found: {path}.")
    return pd.read_csv(path)


def load_donors() -> pd.DataFrame:
    return load_raw("donors_1k.csv")


def load_hospitals() -> pd.DataFrame:
    return load_raw("hospitals.csv")


def load_blood_banks() -> pd.DataFrame:
    return load_raw("blood_banks.csv")


def load_requests() -> pd.DataFrame:
    df = load_raw("blood_requests.csv")
    df["request_time"] = pd.to_datetime(df["request_time"])
    return df
