# ⚙️ Swasthya Backend API

> Flask-based REST API with AI integration

## 🚀 Quick Start

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your API keys

# Run development server
python run.py

# Run with production settings (gunicorn)
gunicorn -w 4 -b 0.0.0.0:8000 app.main:app
```

## 📁 Project Structure

```
backend/
├── app/
│   ├── main.py           # Flask app entry
│   ├── database.py       # MySQL connection
│   ├── models/           # SQLAlchemy models
│   ├── routes/           # API endpoints (24 modules)
│   │   ├── ai_sathi.py   # AI chat & analysis
│   │   ├── live_ai_call.py  # WebSocket voice
│   │   ├── medical_history.py
│   │   ├── doctors.py
│   │   ├── hospitals.py
│   │   ├── simulations.py
│   │   └── ...
│   └── utils/            # Helpers, AI providers
├── migrations/           # Database migrations
├── requirements.txt
└── .env                  # Environment variables
```

## 🔌 API Modules

| Module | Endpoints | Description |
|--------|-----------|-------------|
| `auth` | `/auth/*` | JWT authentication |
| `ai_sathi` | `/ai-sathi/*` | AI chat, symptoms |
| `live_ai_call` | `/live-ai-call/*` | WebSocket voice |
| `doctors` | `/doctors/*` | Doctor CRUD & booking |
| `hospitals` | `/hospitals/*` | Hospital management |
| `medical_history` | `/medical-history/*` | Health records |
| `simulations` | `/simulations/*` | Training modules |
| `emergency` | `/emergency/*` | Emergency contacts |
| `health_alerts` | `/health-alerts/*` | Active alerts |
| `disease_surveillance` | `/disease-surveillance/*` | Outbreak data |

## 🔑 Environment Variables

```env
# Database
DATABASE_URL=mysql://user:pass@localhost/swasthya

# AI Services
GOOGLE_API_KEY=your_gemini_api_key

# JWT
JWT_SECRET=your_jwt_secret_key
JWT_ALGORITHM=HS256

# External APIs
FDA_API_KEY=your_fda_key (optional)
OPENWEATHER_API_KEY=your_weather_key
```

## 🤖 AI Features

| Feature | Provider | Description |
|---------|----------|-------------|
| Chat | Gemini 2.0 | Bilingual health chat |
| Voice Calls | Gemini Live | Real-time voice streaming |
| Report Analysis | Gemini Vision | MRI/CT/Lab OCR |
| Symptom Analysis | Gemini | Triage recommendations |

## 🔨 Database

```bash
# Create tables
python -c "from app.database import init_db; init_db()"

# Seed demo data
mysql -u root -p swasthya < seed_data.sql

# Run migrations
flask db upgrade
```

## 📝 Testing

```bash
# Run tests
pytest

# Test specific module
pytest tests/test_auth.py

# With coverage
pytest --cov=app
```
