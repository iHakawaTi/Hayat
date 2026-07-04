"""
Model 2: Donor Show-Rate Prediction (Engagement Scoring)
Predicts probability a donor will respond/show up when contacted.
Algorithm: LightGBM Classifier with calibrated probabilities.
"""

import numpy as np
import pandas as pd
from sklearn.model_selection import StratifiedKFold, cross_val_score
from sklearn.metrics import (
    roc_auc_score, accuracy_score, classification_report,
    precision_recall_curve, average_precision_score
)
from sklearn.calibration import CalibratedClassifierCV
import lightgbm as lgb
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
    "total_donations", "days_since_last_donation", "months_since_first_donation",
    "avg_response_time_hours", "age", "bmi", "city_enc", "blood_group_enc", "gender_enc"
]

RELIABILITY_TIERS = {
    "High": (0.75, 1.0),
    "Medium": (0.50, 0.75),
    "Low": (0.0, 0.50),
}


def _get_reliability_tier(prob: float) -> str:
    for tier, (low, high) in RELIABILITY_TIERS.items():
        if low <= prob <= high:
            return tier
    return "Low"


class DonorScoringModel:
    """
    LightGBM-based donor engagement scoring model.
    Outputs calibrated show-rate probability and reliability tier.
    """

    def __init__(self):
        self.lgbm = lgb.LGBMClassifier(
            n_estimators=500,
            max_depth=6,
            learning_rate=0.03,
            num_leaves=63,
            min_child_samples=20,
            subsample=0.8,
            colsample_bytree=0.8,
            reg_alpha=0.1,
            reg_lambda=0.5,
            class_weight="balanced",
            random_state=42,
            n_jobs=-1,
            verbosity=-1,
        )
        self.model = None  # Will be CalibratedClassifierCV
        self.feature_cols = FEATURE_COLS
        self.is_trained = False
        self.eval_metrics = {}
        self.feature_importances = {}

    def train(self, X: pd.DataFrame, y: pd.Series):
        """Train with stratified cross-validation + Platt scaling calibration."""
        X = X[self.feature_cols].fillna(0)

        skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
        cv_aucs = cross_val_score(self.lgbm, X, y, cv=skf, scoring="roc_auc", n_jobs=-1)

        # Calibrate probabilities using isotonic regression
        self.model = CalibratedClassifierCV(self.lgbm, cv=5, method="isotonic")
        self.model.fit(X, y)
        self.is_trained = True

        # Evaluate on training set (for reporting)
        preds = self.model.predict(X)
        proba = self.model.predict_proba(X)[:, 1]

        self.eval_metrics = {
            "cv_auc_mean": float(np.mean(cv_aucs)),
            "cv_auc_std": float(np.std(cv_aucs)),
            "train_auc": float(roc_auc_score(y, proba)),
            "train_accuracy": float(accuracy_score(y, preds)),
            "train_avg_precision": float(average_precision_score(y, proba)),
        }
        print(f"  ✅ Donor Scoring trained | CV-AUC: {self.eval_metrics['cv_auc_mean']:.3f} ± {self.eval_metrics['cv_auc_std']:.3f}")

        # Feature importances from base model
        self.lgbm.fit(X, y)
        fi = pd.Series(self.lgbm.feature_importances_, index=self.feature_cols)
        self.feature_importances = fi.sort_values(ascending=False).to_dict()

        return self.eval_metrics

    def predict(self, donor_features: dict) -> dict:
        """
        Score a single donor.
        Input: dict with donor feature values.
        Output: show_rate_probability, reliability_tier, top features.
        """
        if not self.is_trained:
            raise RuntimeError("Model not trained. Call train() or load().")

        row = pd.DataFrame([donor_features])
        for col in self.feature_cols:
            if col not in row.columns:
                row[col] = 0
        X = row[self.feature_cols].fillna(0)

        prob = float(self.model.predict_proba(X)[0][1])
        tier = _get_reliability_tier(prob)

        return {
            "show_rate_probability": round(prob, 4),
            "reliability_tier": tier,
            "is_reliable": prob >= 0.7,
        }

    def predict_batch(self, donors_df: pd.DataFrame) -> pd.DataFrame:
        """Score multiple donors at once."""
        X = donors_df[self.feature_cols].fillna(0)
        probas = self.model.predict_proba(X)[:, 1]
        result = donors_df.copy()
        result["show_rate_probability"] = probas.round(4)
        result["reliability_tier"] = [_get_reliability_tier(p) for p in probas]
        result["is_reliable"] = probas >= 0.7
        return result

    def save(self, path: str = None):
        path = path or os.path.join(MODELS_DIR, "donor_scoring.joblib")
        joblib.dump({
            "model": self.model,
            "metrics": self.eval_metrics,
            "features": self.feature_cols,
            "feature_importances": self.feature_importances,
        }, path)
        print(f"  💾 Saved → {path}")

    def load(self, path: str = None):
        path = path or os.path.join(MODELS_DIR, "donor_scoring.joblib")
        data = joblib.load(path)
        self.model = data["model"]
        self.eval_metrics = data["metrics"]
        self.feature_cols = data["features"]
        self.feature_importances = data.get("feature_importances", {})
        self.is_trained = True
        print(f"  📂 Loaded donor scoring model from {path}")
        return self


if __name__ == "__main__":
    print("=" * 60)
    print("👤 TESTING DONOR SCORING MODEL")
    print("=" * 60)
    np.random.seed(42)
    n = 1000
    X_dummy = pd.DataFrame({
        "total_donations": np.random.poisson(2.5, n),
        "days_since_last_donation": np.random.exponential(120, n),
        "months_since_first_donation": np.random.randint(0, 120, n),
        "avg_response_time_hours": np.random.exponential(4, n),
        "age": np.random.normal(35, 10, n).clip(18, 65),
        "bmi": np.random.normal(26, 4, n).clip(18, 45),
        "city_enc": np.random.randint(0, 7, n),
        "blood_group_enc": np.random.randint(0, 8, n),
        "gender_enc": np.random.binomial(1, 0.9, n),
    })
    y_dummy = np.random.binomial(1, 0.75, n)

    m = DonorScoringModel()
    metrics = m.train(X_dummy, pd.Series(y_dummy))
    print(f"  Metrics: {metrics}")

    result = m.predict({
        "total_donations": 5, "days_since_last_donation": 60,
        "months_since_first_donation": 24, "avg_response_time_hours": 2.0,
        "age": 30, "bmi": 24.0, "city_enc": 0, "blood_group_enc": 0, "gender_enc": 1
    })
    print(f"  Single donor score: {result}")
    m.save()
