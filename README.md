# Hayat (حياة) - Intelligent Blood Donation Platform

<div align="center">
  
  [![Submission](https://img.shields.io/badge/Crown%20Prince%20Award-Submission-gold?style=for-the-badge&logo=award&logoColor=white)](#crown-prince-award)
  
  [![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=Dart&logoColor=white)](https://dart.dev)
  [![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
  [![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
  [![Scikit-Learn](https://img.shields.io/badge/scikit--learn-%23F7931E.svg?style=for-the-badge&logo=scikit-learn&logoColor=white)](https://scikit-learn.org)
  [![Groq](https://img.shields.io/badge/Groq%20AI-F55?style=for-the-badge&logo=openai&logoColor=white)](https://groq.com)

  **A smart, gamified mobile application and machine learning system connecting blood donors with patients in Jordan.**
</div>

---

## 🏆 Crown Prince Award Submission
This project was developed and submitted as an innovation entry for the prestigious **Crown Prince Award** in Jordan. It addresses critical healthcare challenges in Jordan's national blood supply chain by introducing predictive artificial intelligence and modern mobile gamification to motivate, track, and streamline blood donation nationwide.

---

## 📌 Problem Statement & Solution

### The Challenge in Jordan:
1. **Critical Timing**: Finding matching blood donors in emergencies relies on disorganized social media posts or manual calls, causing life-threatening delays.
2. **Donor Retention**: Low rates of recurring donors and a lack of structured incentives/gamification.
3. **Supply Discrepancy**: Blood banks and hospitals frequently experience either acute shortages or wastage due to poor demand forecasting.

### The Hayat Solution:
Hayat connects the entire blood donation ecosystem Donors, Patients, Hospitals, and Blood Banks into a single digital network powered by Machine Learning:
* **For Donors**: A premium Flutter mobile app offering a gamified reward store (redeemable coupons) and a smart pre-donation eligibility check.
* **For Patients & Families**: Instant blood request creation with automated smart-matching that prioritizes donors most likely to show up.
* **For Health Authorities (Ministry of Health)**: Time-series ML demand forecasting to predict blood supply requirements 7 days in advance.

---

## 🛠️ System Architecture

```mermaid
graph TD
    subgraph Frontend [Mobile App - Flutter]
        A[Donor & Patient Screens] --> B[Riverpod State Management]
        B --> C[GoRouter Navigation]
    end

    subgraph AI & Backend [Services]
        D[Supabase Database & Auth]
        E[Groq Llama 3 Chatbot]
    end

    subgraph Machine Learning [Python Pipeline]
        F[Demand Forecasting Model]
        G[Donor Show-Rate Predictor]
        H[Fulfillment Time Regressor]
    end

    A <--> D
    A <--> E
    F & G & H <--> D
```

---

## ✨ Features

### 📱 Flutter Mobile App (`/hayat`)
* **Gamification & Rewards**: Earn points on every donation to redeem rewards/coupons from local partners.
* **AI Health Chatbot**: Integrated Groq AI assistant (Llama-3-8B) to answer donation FAQs, evaluate criteria, and locate hospitals.
* **Streamlined Requests**: Create and track urgent blood requests in real time.
* **Bilingual Support**: Full localization support for English and Arabic.

### 🧠 Machine Learning Engine (`/hayat/blood_donation_ml`)
* **Time-Series Demand Forecasting**: Predicts blood needs per hospital and blood type 7 days ahead.
* **Donor Engagement Scoring**: Analyzes donor profile data to score show rates, helping prioritize donor outreach.
* **Request Fulfillment Regression**: Estimates blood request fulfillment duration to manage patient expectations.
* **Synthetic Data Scaling**: A data simulation pipeline mapping realistic demographics, cities, and MoH structures in Jordan (30,000+ synthetic profiles).

### 📊 Synthetic Data Generation Pipeline (`/hayat/blood_donation_ml/notebooks/Synthetic_Data_Generation.ipynb`)
Due to the strict privacy constraints surrounding patient healthcare records and PII (Personally Identifiable Information), the ML models are trained on high-fidelity synthetic datasets. The generation pipeline leverages the following sophisticated modeling methods to simulate Jordan's blood donation ecosystem:
* **Biological Constraints Modeling**: Utilizes truncated normal distributions to enforce strict physiological limits on medical features (e.g. Age, Weight, Hemoglobin levels, Blood Pressure, Pulse Rate) matching standard whole blood donation eligibility criteria (e.g., minimum weight 50kg, diastolic always less than systolic, normal pulse range).
* **Jordan-Specific Demographics**: 
  - Gender ratios are skewed dynamically matching published Jordanian survey statistics (where males make up >90% of active donors).
  - Blood groups are generated using weighted probability tables matching Jordan's national blood type distribution (e.g., O+ 33.3%, A+ 33.1%, AB- 0.04%).
* **Geographical Mapping**: Cities (Amman, Zarqa, Irbid, Aqaba, Madaba, Jerash) are mapped to their official latitude/longitude centers, with coordinate offsets generated within realistic circular dispersion radii to simulate donor location dispersion.
* **Temporal & Behavioral Features**: Generates historic donation records using Poisson distributions, ensuring a mandatory 56-day (8 weeks) gap between donations, and models show-rates using beta distributions to evaluate donor reliability.
* **Locale-Aware Faker Synthesis**: Employs the `faker` library in Arabic (`ar`) to generate culturally accurate names, email hashes, and mobile patterns prefix-validated for Jordan (`077`, `078`, `079`).

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (`^3.9.2` or later)
* Dart SDK
* Python 3.10+
* A Supabase account

---

### Backend / Environment Setup

1. Copy `.env.example` to `.env` in both the root directory and the `hayat/` directory:
   ```bash
   cp .env.example .env
   cp .env.example hayat/.env
   ```
2. Fill in your Supabase details and Groq API keys in the respective `.env` files:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   GROQ_API_KEY=your-groq-api-key
   ```

---

### Running the Mobile App

Navigate into the `hayat` directory:
```bash
cd hayat

# Fetch dependencies
flutter pub get

# Run on an emulator or connected device
flutter run

# Run on Chrome
flutter run -d chrome
```

---

### Running the Machine Learning Models

Navigate into the ML directory:
```bash
cd hayat/blood_donation_ml

# Install dependencies
pip install -r requirements.txt

# Run the training script for all models
python train_all.py
```

---

## 👥 Contributors & Credits
Developed as an entry for the **Crown Prince Award** for digital innovations improving healthcare logistics in Jordan.
