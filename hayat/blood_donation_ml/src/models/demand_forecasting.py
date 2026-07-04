"""
Model 1: Demand Forecasting
Predicts blood unit demand per blood group per hospital for the next 7 days.
Algorithm: XGBoost Regressor with lag features + time features.
"""

import numpy as np
import pandas as pd
from sklearn.model_selection import TimeSeriesSplit, cross_val_score
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.preprocessing import StandardScaler
import xgboost as xgb
import joblib
import sys
import os
from datetime import datetime, timedelta

sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
from config.settings import BLOOD_GROUPS, MODEL_CONFIG

MODELS_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "models", "saved"
)
os.makedirs(MODELS_DIR, exist_ok=True)

FEATURE_COLS = [
    "blood_group_enc", "day_of_week", "month", "week_of_year",
    "lag_1_units", "lag_7_units", "rolling_7d_mean", "avg_urgency_score"
]


class DemandForecastingModel:
    """
    XGBoost-based blood demand forecasting.
    Predicts units_requested for next 7 days per blood_group × hospital.
    """

    def __init__(self):
        self.model = xgb.XGBRegressor(
            n_estimators=300,
            max_depth=6,
            learning_rate=0.05,
            subsample=0.8,
            colsample_bytree=0.8,
            min_child_weight=3,
            reg_alpha=0.1,
            reg_lambda=1.0,
            random_state=42,
            n_jobs=-1,
            verbosity=0,
        )
        self.feature_cols = FEATURE_COLS
        self.is_trained = False
        self.eval_metrics = {}

    def train(self, features_df: pd.DataFrame):
        """Train on aggregated demand features."""
        df = features_df.dropna(subset=self.feature_cols + ["units_requested"])
        X = df[self.feature_cols].values
        y = df["units_requested"].values

        # Time-series cross-validation
        tscv = TimeSeriesSplit(n_splits=5)
        cv_scores = []
        for train_idx, val_idx in tscv.split(X):
            self.model.fit(X[train_idx], y[train_idx],
                           eval_set=[(X[val_idx], y[val_idx])],
                           verbose=False)
            preds = self.model.predict(X[val_idx])
            preds = np.maximum(preds, 0)
            mae = mean_absolute_error(y[val_idx], preds)
            cv_scores.append(mae)

        # Final fit on all data
        self.model.fit(X, y, verbose=False)
        self.is_trained = True

        preds_all = np.maximum(self.model.predict(X), 0)
        self.eval_metrics = {
            "cv_mae_mean": float(np.mean(cv_scores)),
            "cv_mae_std": float(np.std(cv_scores)),
            "train_mae": float(mean_absolute_error(y, preds_all)),
            "train_rmse": float(np.sqrt(mean_squared_error(y, preds_all))),
            "train_r2": float(r2_score(y, preds_all)),
        }
        print(f"  ✅ Demand Forecasting trained | CV-MAE: {self.eval_metrics['cv_mae_mean']:.2f} ± {self.eval_metrics['cv_mae_std']:.2f}")
        return self.eval_metrics

    def predict(self, features: dict) -> dict:
        """
        Predict demand for a single blood_group × hospital scenario.
        features: dict with keys matching FEATURE_COLS
        """
        if not self.is_trained:
            raise RuntimeError("Model not trained. Call train() or load().")

        row = pd.DataFrame([features])
        for col in self.feature_cols:
            if col not in row.columns:
                row[col] = 0
        X = row[self.feature_cols].values
        pred = float(np.maximum(self.model.predict(X)[0], 0))
        return {
            "predicted_units": round(pred, 2),
            "predicted_units_rounded": int(round(pred)),
        }

    def predict_7day_forecast(self, blood_group_enc: int, hospital_id: str,
                               last_known_units: list, day_of_week_start: int,
                               month: int, week_of_year: int,
                               avg_urgency_score: float = 1.5) -> list:
        """
        Generate a 7-day ahead forecast by iterating predictions.
        """
        forecast = []
        lag_window = list(last_known_units[-7:]) if len(last_known_units) >= 7 else last_known_units + [0] * (7 - len(last_known_units))
        lag_1 = last_known_units[-1] if last_known_units else 0
        rolling_mean = float(np.mean(lag_window))

        for day_offset in range(7):
            dow = (day_of_week_start + day_offset) % 7
            features = {
                "blood_group_enc": blood_group_enc,
                "day_of_week": dow,
                "month": month,
                "week_of_year": (week_of_year + day_offset // 7) % 52 + 1,
                "lag_1_units": lag_1,
                "lag_7_units": lag_window[day_offset] if day_offset < len(lag_window) else 0,
                "rolling_7d_mean": rolling_mean,
                "avg_urgency_score": avg_urgency_score,
            }
            result = self.predict(features)
            pred = result["predicted_units"]
            forecast.append({
                "day_offset": day_offset + 1,
                "predicted_units": result["predicted_units"],
                "predicted_units_rounded": result["predicted_units_rounded"],
            })
            lag_window.append(pred)
            lag_1 = pred
            rolling_mean = float(np.mean(lag_window[-7:]))

        return forecast

    def save(self, path: str = None):
        path = path or os.path.join(MODELS_DIR, "demand_forecasting.joblib")
        joblib.dump({"model": self.model, "metrics": self.eval_metrics, "features": self.feature_cols}, path)
        print(f"  💾 Saved → {path}")

    def load(self, path: str = None):
        path = path or os.path.join(MODELS_DIR, "demand_forecasting.joblib")
        data = joblib.load(path)
        self.model = data["model"]
        self.eval_metrics = data["metrics"]
        self.feature_cols = data["features"]
        self.is_trained = True
        print(f"  📂 Loaded demand model from {path}")
        return self


if __name__ == "__main__":
    # Quick standalone test
    print("=" * 60)
    print("📈 TESTING DEMAND FORECASTING MODEL")
    print("=" * 60)
    # Create dummy data
    np.random.seed(42)
    dates = pd.date_range("2024-01-01", periods=200)
    dummy = pd.DataFrame({
        "blood_group_enc": np.random.randint(0, 8, 200),
        "day_of_week": dates.dayofweek,
        "month": dates.month,
        "week_of_year": dates.isocalendar().week.astype(int),
        "lag_1_units": np.random.randint(1, 30, 200),
        "lag_7_units": np.random.randint(1, 30, 200),
        "rolling_7d_mean": np.random.uniform(5, 25, 200),
        "avg_urgency_score": np.random.uniform(0.5, 3.0, 200),
        "units_requested": np.random.randint(1, 50, 200),
    })
    m = DemandForecastingModel()
    metrics = m.train(dummy)
    print(f"  Metrics: {metrics}")
    forecast = m.predict_7day_forecast(
        blood_group_enc=0, hospital_id="HOS001",
        last_known_units=[10, 12, 15, 8, 20, 11, 9],
        day_of_week_start=0, month=5, week_of_year=18
    )
    print(f"  7-day forecast: {forecast}")
    m.save()
