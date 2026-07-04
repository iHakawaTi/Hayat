"""
Donor Data Generator - Jordan-Specific Synthetic Blood Donors
Based on MoH statistics and medical constraints.
"""

from faker import Faker
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
import hashlib
import sys
import os

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from config.settings import (
    MEDICAL_CONSTRAINTS, BLOOD_GROUPS, BLOOD_GROUP_PROBABILITIES,
    JORDAN_CITIES, JORDAN_CITY_PROBABILITIES, CITY_CENTERS,
    GENDER_DISTRIBUTION_BY_AGE, RANDOM_SEED
)


class MedicalDonorDataGenerator:
    """
    Generates synthetic blood donor data with Jordan-specific demographics
    and medical constraints for blood donation eligibility.
    """
    
    def __init__(self, n_samples=1000, seed=RANDOM_SEED):
        self.n_samples = n_samples
        self.fake = Faker('ar')  # Arabic
        np.random.seed(seed)
        Faker.seed(seed)
        
        self.constraints = MEDICAL_CONSTRAINTS
        self.blood_groups = BLOOD_GROUPS
        self.blood_group_probabilities = BLOOD_GROUP_PROBABILITIES
        self.jordan_cities = JORDAN_CITIES
        self.jordan_city_probabilities = JORDAN_CITY_PROBABILITIES
        self.city_centers = CITY_CENTERS

    def _generate_constrained_normal(self, constraint_key, size=None):
        """Generate values from truncated normal distribution"""
        c = self.constraints[constraint_key]
        values = np.random.normal(c['mean'], c['std'], size or self.n_samples)
        return np.clip(values, c['min'], c['max'])

    def _generate_bmi(self, weight, height):
        """Calculate BMI from weight and height"""
        return weight / ((height / 100) ** 2)

    def _generate_jordan_coordinates(self, city):
        """Generate realistic coordinates within a specific Jordan city"""
        if city not in self.city_centers:
            city = 'Other'
            
        center_lat, center_lon, radius = self.city_centers[city]
        
        # Generate random offset within circle (uniform distribution)
        angle = np.random.uniform(0, 2 * np.pi)
        r = radius * np.sqrt(np.random.uniform(0, 1))
        
        lat = round(center_lat + r * np.cos(angle), 6)
        lon = round(center_lon + r * np.sin(angle), 6)
        
        return lat, lon

    def _generate_donation_history(self):
        """Generate realistic donation patterns with eligibility constraints"""
        # Poisson distribution - most donors have 1-5 donations
        total_donations = np.random.poisson(2.5, self.n_samples)
        total_donations = np.clip(total_donations, 0, 50)
        
        # Days since last donation - minimum 56 days (8 weeks) for whole blood
        min_days = self.constraints['min_days_between_donations']
        max_days = self.constraints['max_days_since_last_donation']
        
        days_since_last = np.random.exponential(120, self.n_samples).astype(int)
        days_since_last = np.clip(days_since_last, min_days, max_days)
        
        # For donors with 0 donations, set days_since_last to high value
        days_since_last = np.where(total_donations == 0, 365, days_since_last)
        
        # Months since first donation
        min_months = (total_donations - 1) * 2
        months_since_first = np.random.randint(0, 120, self.n_samples)
        months_since_first = np.maximum(months_since_first, min_months)
        months_since_first = np.where(total_donations == 0, 0, months_since_first)
        
        return total_donations, days_since_last, months_since_first

    def _generate_jordan_mobile(self):
        """Generate valid Jordanian mobile number"""
        prefixes = ['077', '078', '079']
        return f'{np.random.choice(prefixes)}{np.random.randint(1000000, 9999999)}'

    def _generate_medications(self):
        """Generate realistic medication list or None"""
        if np.random.random() < 0.3:  # 30% on medications
            meds = np.random.choice(
                ['Aspirin', 'Metformin', 'Lisinopril', 'Atorvastatin'],
                size=np.random.randint(1, 3),
                replace=False
            )
            return ', '.join(meds)
        return 'None'

    def _generate_response_history(self, total_donations, show_rate):
        """Generate response history array correlated with show_rate"""
        if total_donations == 0:
            return '[]'
        prob_respond = max(0.1, min(0.95, show_rate))
        responses = np.random.choice(
            ['responded', 'no_response'],
            size=total_donations,
            p=[prob_respond, 1 - prob_respond]
        )
        return str(responses.tolist())

    def _get_gender_for_age(self, age):
        """Get gender based on age with Jordan-specific distribution"""
        if age < 30:
            probs = GENDER_DISTRIBUTION_BY_AGE['under_30']
        elif age < 45:
            probs = GENDER_DISTRIBUTION_BY_AGE['30_to_45']
        else:
            probs = GENDER_DISTRIBUTION_BY_AGE['over_45']
        
        return np.random.choice(['Male', 'Female'], p=[probs['Male'], probs['Female']])

    def generate(self):
        """Main generation method"""
        data = []
        
        # Pre-generate donation history for all samples
        total_donations, days_since, months_since = self._generate_donation_history()
        
        for i in range(self.n_samples):
            age = int(self._generate_constrained_normal('age', 1)[0])
            gender = self._get_gender_for_age(age)
            
            # Physical measurements
            weight = self._generate_constrained_normal('weight', 1)[0]
            
            # Height varies by gender
            if gender == 'Male':
                height = np.random.normal(174, 8)
                height = np.clip(height, 155, 200)
            else:
                height = np.random.normal(159, 7)
                height = np.clip(height, 145, 185)
            
            bmi = self._generate_bmi(weight, height)
            
            # Vitals
            systolic = int(self._generate_constrained_normal('systolic_bp', 1)[0])
            diastolic = int(self._generate_constrained_normal('diastolic_bp', 1)[0])
            
            # Ensure diastolic < systolic
            if diastolic >= systolic:
                diastolic = systolic - np.random.randint(20, 40)
                diastolic = max(diastolic, 60)
            
            pulse = int(self._generate_constrained_normal('pulse', 1)[0])
            
            # Hemoglobin based on gender
            hemo_key = 'hemoglobin_male' if gender == 'Male' else 'hemoglobin_female'
            hemoglobin = round(self._generate_constrained_normal(hemo_key, 1)[0], 1)
            
            # Donation metrics
            total_litres = round(total_donations[i] * 0.45, 2)
            last_donation_date = datetime.now() - timedelta(days=int(days_since[i]))
            
            # City selection
            city = np.random.choice(self.jordan_cities, p=self.jordan_city_probabilities)
            lat, lon = self._generate_jordan_coordinates(city)
            
            # Behavior metrics
            show_rate = round(np.random.beta(8, 2), 2)
            
            record = {
                'donor_code': f'JD{str(i+1).zfill(6)}',
                'full_name': self.fake.name(),
                'gender': gender,
                'age': age,
                'weight_kg': round(weight, 1),
                'height_cm': round(height, 1),
                'blood_pressure': f'{systolic}/{diastolic}',
                'systolic_bp': systolic,
                'diastolic_bp': diastolic,
                'pulse_rate': pulse,
                'latitude': lat,
                'longitude': lon,
                'bmi': round(bmi, 2),
                'hemoglobin_g_dl': hemoglobin,
                'medications': self._generate_medications(),
                'email': self.fake.email(),
                'mobile': self._generate_jordan_mobile(),
                'city': city,
                'blood_group': np.random.choice(self.blood_groups, p=self.blood_group_probabilities),
                'availability': np.random.choice(['Yes', 'No'], p=[0.45, 0.55]),
                'months_since_first_donation': int(months_since[i]),
                'days_since_last_donation': int(days_since[i]),
                'total_donations': int(total_donations[i]),
                'total_litres_donated': total_litres,
                'last_donation_date': last_donation_date.strftime('%Y-%m-%d'),
                'show_rate': show_rate,
                'avg_response_time_hours': round(np.random.exponential(4), 1),
                'response_history': self._generate_response_history(int(total_donations[i]), show_rate),
                'record_created': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }
            
            data.append(record)
        
        return pd.DataFrame(data)


def main():
    """Generate and save donor data"""
    print("=" * 60)
    print("🩸 GENERATING JORDAN BLOOD DONOR DATA")
    print("=" * 60)
    
    generator = MedicalDonorDataGenerator(n_samples=1000)
    df = generator.generate()
    
    # Save to data/raw
    output_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
        'data', 'raw', 'donors_1k.csv'
    )
    df.to_csv(output_path, index=False)
    
    print(f"\n✅ Generated {len(df)} donors")
    print(f"📁 Saved to: {output_path}")
    print(f"\n📊 Blood Group Distribution:")
    print(df['blood_group'].value_counts(normalize=True).round(3))
    print(f"\n📍 City Distribution:")
    print(df['city'].value_counts())
    
    return df


if __name__ == "__main__":
    main()
