"""
Jordan Blood Donation ML System - Configuration
Contains medical constraints, Jordan-specific demographics, and system settings.
"""

import numpy as np

# =============================================================================
# MEDICAL CONSTRAINTS (Blood Donation Eligibility)
# =============================================================================
MEDICAL_CONSTRAINTS = {
    # Age: Standard eligibility 18-65; mean ~35 for active donor pool
    'age': {'min': 18, 'max': 65, 'mean': 35, 'std': 10},
    
    # Weight: Min 50kg for whole blood; mean ~75kg typical adult in Jordan
    'weight': {'min': 50, 'max': 120, 'mean': 75, 'std': 15},
    
    # Height by gender (Jordan averages from Wikipedia)
    'height_male': {'min': 155, 'max': 200, 'mean': 174, 'std': 8},
    'height_female': {'min': 145, 'max': 185, 'mean': 159, 'std': 7},
    
    # Hemoglobin Males: Min 12.5 g/dL eligibility
    'hemoglobin_male': {'min': 12.5, 'max': 17.5, 'mean': 14, 'std': 1},
    
    # Hemoglobin Females: Min 12.0 g/dL eligibility
    'hemoglobin_female': {'min': 12.0, 'max': 16.0, 'mean': 13.2, 'std': 1},
    
    # Blood Pressure limits
    'systolic_bp': {'min': 90, 'max': 160, 'mean': 120, 'std': 12},
    'diastolic_bp': {'min': 60, 'max': 100, 'mean': 80, 'std': 8},
    
    # Pulse: Standard 60-100 bpm eligible
    'pulse': {'min': 60, 'max': 100, 'mean': 72, 'std': 8},
    
    # Donation intervals
    'min_days_between_donations': 56,  # 8 weeks for whole blood
    'max_days_since_last_donation': 730,  # 2 years
}

# =============================================================================
# JORDAN BLOOD TYPE DISTRIBUTION
# Source: Wikipedia - Blood Type Distribution by Country, Jordan Journal of Medical Sciences
# =============================================================================
BLOOD_GROUPS = ['O+', 'A+', 'B+', 'AB+', 'O-', 'A-', 'B-', 'AB-']
BLOOD_GROUP_PROBABILITIES = [0.3338, 0.3307, 0.1668, 0.0633, 0.0443, 0.0400, 0.0207, 0.0004]

# =============================================================================
# JORDAN CITIES & DEMOGRAPHICS
# Source: World Population Review, Citypopulation.de (2026 estimates)
# =============================================================================
JORDAN_CITIES = ['Amman', 'Zarqa', 'Irbid', 'Aqaba', 'Madaba', 'Jerash', 'Other']
JORDAN_CITY_PROBABILITIES = [0.448, 0.149, 0.111, 0.019, 0.016, 0.005, 0.252]

# City GPS coordinates (verified from latlong.info, Wikipedia)
CITY_CENTERS = {
    'Amman': (31.95522, 35.94503, 0.15),    # lat, lon, radius in degrees
    'Zarqa': (32.0809, 36.1059, 0.08),
    'Irbid': (32.5556, 35.8500, 0.08),
    'Aqaba': (29.5321, 35.0063, 0.05),
    'Madaba': (31.7276, 35.8012, 0.04),
    'Jerash': (32.2747, 35.8961, 0.03),
    'Karak': (31.1853, 35.7048, 0.05),
    'Mafraq': (32.3405, 36.2085, 0.05),
    'Other': (31.0000, 36.0000, 0.50),      # Jordan geographic center
}

# Gender distribution by age (Source: PMC11159535 - Jordan survey 2024)
# "more than 90% of donors are male"
GENDER_DISTRIBUTION_BY_AGE = {
    'under_30': {'Male': 0.88, 'Female': 0.12},
    '30_to_45': {'Male': 0.92, 'Female': 0.08},
    'over_45': {'Male': 0.95, 'Female': 0.05},
}

# =============================================================================
# REQUEST URGENCY CONFIGURATION
# =============================================================================
URGENCY_LEVELS = ["Low", "Medium", "High", "Critical"]
URGENCY_PROBABILITIES = [0.35, 0.40, 0.20, 0.05]

UNITS_BY_URGENCY = {
    "Low": (1, 2),
    "Medium": (2, 4),
    "High": (4, 8),
    "Critical": (6, 15),
}

# Reason categories (non-PHI)
REQUEST_REASONS = [
    "Surgery Preparation",
    "Emergency Trauma",
    "Cancer Treatment",
    "Anemia Support",
    "Childbirth / OB",
    "Thalassemia / Chronic",
    "ICU Demand",
]
REQUEST_REASON_PROBABILITIES = [0.18, 0.18, 0.14, 0.16, 0.12, 0.12, 0.10]

# Blood components
BLOOD_COMPONENTS = ["Whole Blood", "RBC", "Plasma", "Platelets"]
COMPONENT_PROBABILITIES = [0.55, 0.25, 0.12, 0.08]

# =============================================================================
# SUPABASE CONFIGURATION
# =============================================================================
SUPABASE_URL = "https://ltjvpcufqwtikzonsmww.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx0anZwY3VmcXd0aWt6b25zbXd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1MDMwNDksImV4cCI6MjA4NDA3OTA0OX0.wGs7ImnKco62c-8pFN3HuJxEgjg9Ra9OTf2k7dDIhHU"

# Table names in Supabase
SUPABASE_TABLES = {
    'donors': 'donors',
    'hospitals': 'hospitals',
    'blood_banks': 'blood_banks',
    'blood_requests': 'blood_requests',
    'v_requests': 'v_requests',  # View
}

# =============================================================================
# ML MODEL CONFIGURATION
# =============================================================================
MODEL_CONFIG = {
    'demand_forecasting': {
        'forecast_horizon_days': 7,
        'training_window_days': 60,
        'features': ['blood_group', 'hospital_type', 'day_of_week', 'month', 'is_holiday'],
    },
    'donor_scoring': {
        'target': 'show_rate',
        'features': [
            'total_donations', 'days_since_last_donation', 'months_since_first_donation',
            'avg_response_time_hours', 'age', 'city', 'blood_group'
        ],
    },
    'request_fulfillment': {
        'target': 'time_to_fulfill_hours',
        'features': ['urgency', 'blood_group', 'units_needed', 'stock_status', 'hour_of_day'],
    },
}

# =============================================================================
# RANDOM SEEDS
# =============================================================================
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)
