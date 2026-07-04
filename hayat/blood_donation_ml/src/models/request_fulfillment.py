"""
Model 3: Request Fulfillment Time Prediction
Estimates how long a blood request will take to fulfill (in hours).
Algorithm: XGBoost Regressor on log-transformed target.
"""

import numpy as np
import pandas as pd
from sklearn.model_selection import KFold, cross_val_score
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
import xgboost as xgb
import joblib
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
from config.settings import MODEL_CONFIG

MODELS_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "models", "saved"
)
os.makedirs(MODELS_DIR, exist_ok=True)

FEATURE_COLS = [
    "urgency_enc", "blood_group_enc", "units_needed", "stock_level_enc",
    "hour_of_day", "day_of_week", "month", "is_weekend", "is_holiday",
    "is_rare_blood",
]

URGENCY_MAP = {"Low": 0, "Medium": 1, "High": 2, "Critical": 3}
BLOOD_GROUP_MAP = {"O+": 0, "A+": 1, "B+": 2, "AB+": 3, "O-": 4, "A-": 5, "B-": 6, "AB-": 7}
STOCK_MAP = {"Low": 0, "Medium": 1, "High": 2}
RARE_GROUPS = {"AB-", "B-", "O-"}


class RequestFulfillmentModel:
    """
    XGBoost regressor for request fulfillment time estimation.
    Predicts log(hours) and converts back for output.
    """

    def __init__(self):
        self.model = xgb.XGBRegressor(
            n_estimators=400,
            max_depth=6,
            learning_rate=0.04,
            subsample=0.8,
            colsample_bytree=0.8,
            min_child_weight=5,
            reg_alpha=0.2,
            reg_lambda=1.5,
            random_state=42,
            n_jobs=-1,
            verbosity=0,
        )
        self.feature_cols = FEATURE_COLS
        self.is_trained = False
        self.eval_metrics = {}

    def train(self, X: pd.DataFrame, y_log: pd.Series):
        """
        Train on log-transformed fulfillment hours.
        X: feature DataFrame, y_log: np.log1p(hours).
        """
        X = X[self.feature_cols].fillna(0)

        kf = KFold(n_splits=5, shuffle=True, random_state=42)
        cv_maes_log = cross_val_score(self.model, X, y_log, cv=kf,
                                       scoring="neg_mean_absolute_error", n_jobs=-1)
        cv_maes_log = -cv_maes_log

        # Final model fit
        self.model.fit(X, y_log)
        self.is_trained = True

        preds_log = self.model.predict(X)
        preds_hours = np.expm1(preds_log)
        true_hours = np.expm1(y_log)

        self.eval_metrics = {
            "cv_mae_log_mean": float(np.mean(cv_maes_log)),
            "cv_mae_log_std": float(np.std(cv_maes_log)),
            "train_mae_hours": float(mean_absolute_error(true_hours, preds_hours)),
            "train_rmse_hours": float(np.sqrt(mean_squared_error(true_hours, preds_hours))),
            "train_r2_log": float(r2_score(y_log, preds_log)),
        }
        print(f"  ✅ Fulfillment model trained | CV-MAE(log): {self.eval_metrics['cv_mae_log_mean']:.3f} ± {self.eval_metrics['cv_mae_log_std']:.3f}")
        print(f"     Train MAE (hours): {self.eval_metrics['train_mae_hours']:.2f}h | RMSE: {self.eval_metrics['train_rmse_hours']:.2f}h")
        return self.eval_metrics

    def predict(self, request_features: dict) -> dict:
        """
        Predict fulfillment time for a single blood request.
        Input: dict with request context values.
        Output: estimated hours + confidence band + urgency label.
        """
        if not self.is_trained:
            raise RuntimeError("Model not trained. Call train() or load().")

        # Encode from string inputs if provided
        features = self._encode(request_features)
        row = pd.DataFrame([features])
        for col in self.feature_cols:
            if col not in row.columns:
                row[col] = 0
        X = row[self.feature_cols].fillna(0)

        log_pred = float(self.model.predict(X)[0])
        hours = float(np.expm1(log_pred))
        hours = max(0.5, hours)

        # Simple ±20% confidence interval
        low = max(0.5, hours * 0.8)
        high = hours * 1.2

        return {
            "estimated_fulfillment_hours": round(hours, 2),
            "confidence_low_hours": round(low, 2),
            "confidence_high_hours": round(high, 2),
            "fulfillment_category": self._category(hours),
        }

    def _encode(self, features: dict) -> dict:
        """Encode string labels to ints if necessary."""
        f = features.copy()
        if isinstance(f.get("urgency"), str):
            f["urgency_enc"] = URGENCY_MAP.get(f.pop("urgency", "Medium"), 1)
        if isinstance(f.get("blood_group"), str):
            bg = f.pop("blood_group", "O+")
            f["blood_group_enc"] = BLOOD_GROUP_MAP.get(bg, 0)
            f["is_rare_blood"] = int(bg in RARE_GROUPS)
        if isinstance(f.get("stock_level"), str):
            f["stock_level_enc"] = STOCK_MAP.get(f.pop("stock_level", "Medium"), 1)
        return f

    @staticmethod
    def _category(hours: float) -> str:
        if hours <= 4:
            return "Fast (<4h)"
        elif hours <= 24:
            return "Same Day (4-24h)"
        elif hours <= 72:
            return "2-3 Days"
        else:
            return "Extended (>3 days)"

    def save(self, path: str = None):
        path = path or os.path.join(MODELS_DIR, "request_fulfillment.joblib")
        joblib.dump({
            "model": self.model,
            "metrics": self.eval_metrics,
            "features": self.feature_cols,
        }, path)
        print(f"  💾 Saved → {path}")

    def load(self, path: str = None):
        path = path or os.path.join(MODELS_DIR, "request_fulfillment.joblib")
        data = joblib.load(path)
        self.model = data["model"]
        self.eval_metrics = data["metrics"]
        self.feature_cols = data["features"]
        self.is_trained = True
        print(f"  📂 Loaded fulfillment model from {path}")
        return self


if __name__ == "__main__":
    print("=" * 60)
    print("⏱️  TESTING REQUEST FULFILLMENT MODEL")
    print("=" * 60)
    np.random.seed(42)
    n = 2000
    X_dummy = pd.DataFrame({
        "urgency_enc": np.random.randint(0, 4, n),
        "blood_group_enc": np.random.randint(0, 8, n),
        "units_needed": np.random.randint(1, 15, n),
        "stock_level_enc": np.random.randint(0, 3, n),
        "hour_of_day": np.random.randint(0, 24, n),
        "day_of_week": np.random.randint(0, 7, n),
        "month": np.random.randint(1, 13, n),
        "is_weekend": np.random.randint(0, 2, n),
        "is_holiday": np.random.binomial(1, 0.05, n),
        "is_rare_blood": np.random.binomial(1, 0.07, n),
    })
    y_dummy = np.log1p(np.random.exponential(20, n).clip(0.5, 200))

    m = RequestFulfillmentModel()
    metrics = m.train(X_dummy, pd.Series(y_dummy))
    print(f"  Metrics: {metrics}")

    result = m.predict({
        "urgency": "High", "blood_group": "AB-",
        "units_needed": 6, "stock_level": "Low",
        "hour_of_day": 2, "day_of_week": 6,
        "month": 5, "is_weekend": 1, "is_holiday": 0,
    })
    print(f"  Single request prediction: {result}")
    m.save()
