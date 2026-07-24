# PDD Wound Healing & Oral Health AI App

An AI-powered Flutter & FastAPI mobile and web application for oral health assessment and wound healing monitoring.

## Features
- **Oral Health & Wound Assessment**: AI-driven analysis of oral lesions and wound progress.
- **Cross-Platform Flutter Frontend**: Responsive UI for Android, iOS, and Web.
- **FastAPI Backend**: Robust microservices backend with image processing and API integration.
- **Appium & Selenium Automated E2E Tests**: Comprehensive test suite for mobile and web.

## Getting Started

### Flutter App (Frontend)
```bash
flutter pub get
flutter run
```

### FastAPI Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Automated Testing
```bash
cd appium_tests
pip install -r requirements.txt
python run_e2e_tests.py
```
