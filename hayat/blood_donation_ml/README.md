# Blood Donation ML System - Crown Prince Award Competition

A comprehensive ML-powered blood donation management system for Jordan, featuring:
- **Synthetic Data Generation** - Realistic donor, hospital, and request data
- **Demand Forecasting** - Predict blood needs per hospital/blood type
- **Donor Engagement Scoring** - Predict donor show rates and response
- **Smart Matching** - Optimize donor-request matching

## Project Structure

```
blood_donation_ml/
├── config/                  # Configuration files
│   └── settings.py          # Global settings and constraints
├── data/
│   ├── raw/                 # Original generated data
│   └── processed/           # Cleaned, feature-engineered data
├── src/
│   ├── generators/          # Synthetic data generation
│   │   ├── donor_generator.py
│   │   ├── donor_scaler.py
│   │   ├── hospital_generator.py
│   │   ├── blood_bank_generator.py
│   │   └── request_generator.py
│   ├── features/            # Feature engineering
│   │   └── feature_engineering.py
│   ├── models/              # ML models
│   │   ├── demand_forecasting.py
│   │   ├── donor_scoring.py
│   │   └── request_fulfillment.py
│   └── utils/               # Utility functions
│       ├── supabase_client.py
│       └── data_loader.py
├── notebooks/               # Jupyter notebooks for exploration
├── api/                     # API endpoints (FastAPI/Flask)
└── requirements.txt
```

## Getting Started

```bash
# Install dependencies
pip install -r requirements.txt

# Generate synthetic data
python -m src.generators.donor_generator
python -m src.generators.hospital_generator
python -m src.generators.blood_bank_generator
python -m src.generators.request_generator

# Scale donor data (1K → 30K)
python -m src.generators.donor_scaler
```

## Data Sources

- **Donors**: 30,000 synthetic donors with Jordan-specific demographics
- **Hospitals**: 21 hospitals (real + synthetic based on MoH structure)
- **Blood Banks**: 15 blood banks (5 verified + 10 synthetic)
- **Requests**: 3,000 blood requests with urgency levels

## ML Models

1. **Demand Forecasting** - Time series prediction of blood needs
2. **Donor Show-Rate Prediction** - Binary classification for donor reliability
3. **Request Fulfillment Time** - Regression for estimating fulfillment duration

## Competition Focus

This project aims to optimize Jordan's blood supply chain by:
- Predicting demand 7 days ahead
- Prioritizing reliable donors
- Reducing blood wastage
- Improving emergency response times
