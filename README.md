# AI-Powered Upskilling Recommendation and Automation System for Students

## Project Overview

A complete AI-Powered Upskilling Recommendation and Automation System for Students with a Flutter frontend, FastAPI backend, PostgreSQL database, and configurable AI provider (Gemini/Ollama) integration. The system helps students understand their current skill set, identify suitable career paths, determine skills they need to develop, and follow a structured learning roadmap.

## System Status

**✅ Fully Implemented:**
- All 16 Flutter screens with Material 3, Riverpod, GoRouter
- FastAPI backend with all 10 modules (auth, profile, skills, careers, roadmap, progress, AI)
- PostgreSQL database with 13 tables and proper relationships
- Configurable AI engine supporting Gemini, Ollama, and compatible providers
- JWT authentication with session persistence
- AI response validation with Pydantic schemas
- Demo mode when API key not provided
- Light/dark themes and responsive layouts

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                              │
│  • 16 Material 3 screens (GoRouter, Riverpod, Dio)             │
│  • Authentication with token persistence                        │
│  • Light/dark themes, responsive layouts                        │
│  • Reusable widgets (AppBar, LoadingIndicator, ErrorMessage)    │
└───────────────────────▲─────────────────────────────────────────┘
                      │ REST API (Dio)
┌───────────────────────▼─────────────────────────────────────────┐
│                     FASTAPI BACKEND                              │
│  • 13 PostgreSQL tables (SQLAlchemy models)                     │
│  • JWT authentication (bcrypt hashing, 30-min tokens)           │
│  • Configurable AI service (Gemini/Ollama/compatible)            │
│  • All 10 modules: auth, profile, skills, careers, roadmap,     │
│    progress, AI, plus resources, recommendations                 │
│  • Alembic migrations for database versioning                    │
└───────────────────────▲─────────────────────────────────────────┘
                      │ PostgreSQL
┌───────────────────────▼─────────────────────────────────────────┐
│                       DATABASE (PostgreSQL)                      │
│  • 13 tables: users, student_profiles, student_skills,           │
│    careers, career_required_skills, career_recommendations,       │
│    skill_gap_analyses, learning_roadmaps, roadmap_versions,       │
│    roadmap_phases, roadmap_tasks, learning_resources,            │
│    task_progress                                              │
│  • Proper foreign keys, cascading deletes, indexes               │
│  • Seed data for careers and required skills                      │
└───────────────────────────────────────────────────────────────────┘
```

## Technology Stack

### Frontend
- **Flutter** with Dart
- **Material 3** UI design
- **Riverpod** state management
- **GoRouter** navigation (16 routes)
- **Dio** HTTP client
- **Shared Preferences** for token persistence

### Backend
- **FastAPI** (Python)
- **SQLAlchemy 2.0** ORM
- **Alembic** database migrations
- **Pydantic** validation (v2.7.4)
- **Passlib** bcrypt password hashing

### Database
- **PostgreSQL**
- 13 related tables with proper relationships
- SQLAlchemy models with cascading behavior
- Enum types for proficiency levels and task status

### AI
- **Configurable AI engine** supporting:
  - **Gemini API** (Google Generative AI)
  - **Ollama** (local LLMs, default: http://localhost:11434)
  - **Compatible providers** (OpenAI-style APIs)
- **Demo mode** when no API key configured
- **Structured response validation** with Pydantic schemas
- **Bounded retries** with timeout handling
- **Deterministic calculations** for skill gaps + AI interpretation

## Quick Start

### Prerequisites
- macOS (Apple Silicon recommended)
- Flutter SDK (3.+)
- Python 3.10+
- PostgreSQL 13+
- (Optional) Google Gemini API key or local Ollama setup

### Backend Setup

1. **Install dependencies:**
```bash
cd backend
pip install -r requirements.txt
```

2. **Set up environment variables:**
```bash
export DATABASE_URL="postgresql://localhost:5432/upskilling"
export AI_PROVIDER="gemini"  # or "ollama" or "compatible"
export AI_MODEL="gemini-pro"  # model name for chosen provider
export AI_API_KEY="your-gemini-key"  # empty for Ollama/compatible
export JWT_SECRET_KEY="change-this-in-production"
export ENVIRONMENT="development"
```

3. **Initialize database:**
```bash
# Create the database
createdb upskilling

# Run migrations
cd backend
/opt/homebrew/bin/python3 -c "
import os
os.environ['DATABASE_URL'] = 'postgresql://localhost:5432/upskilling'
from alembic.config import Config
config = Config('alembic.ini')
command.upgrade(config, 'head')
" 2>&1 || alembic upgrade head
```

4. **Start the backend:**
```bash
cd backend
/opt/homebrew/bin/python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Frontend Setup

1. **Install dependencies:**
```bash
cd .freebuff/flutter_upskilling
flutter pub get
```

2. **Run the app:**
```bash
flutter run
```

### AI Provider Configuration

#### Gemini API
```bash
export AI_PROVIDER="gemini"
export AI_MODEL="gemini-pro"  # or gemini-1.5-flash, etc.
export AI_API_KEY="your-google-gemini-api-key"
```

#### Ollama (Local)
```bash
export AI_PROVIDER="ollama"
export AI_MODEL="llama2"  # or any installed Ollama model
# No API key needed - Ollama runs locally
# Ensure Ollama is running: ollama serve
```

#### Compatible Provider (OpenAI-style)
```bash
export AI_PROVIDER="compatible"
export AI_BASE_URL="https://api.openai.com/v1"
export AI_MODEL="gpt-4"
export AI_API_KEY="your-openai-key"
```

#### Demo Mode (No API Key)
```bash
export AI_PROVIDER="gemini"
export AI_API_KEY=""  # Leave empty
# Application runs in demo mode with structured mock responses
```

## API Endpoints

### Authentication
| Endpoint | Description |
|---|---|
| `POST /api/auth/register` | Register new user (email, username, password) |
| `POST /api/auth/login` | Login, receive JWT token |
| `GET /api/profile` | Get current user profile (requires token) |
| `POST /api/profile` | Update profile |

### AI Services
| Endpoint | Description |
|---|---|
| `GET /health` | Health check with AI status |
| `GET /api/ai/status` | AI provider status |
| `POST /api/ai/career-recommendations` | Get career recommendations |
| `POST /api/ai/skill-gap-analysis` | Analyze skill gaps |
| `POST /api/ai/personalized-skills` | Get skill suggestions |
| `POST /api/ai/roadmap-generate` | Generate learning roadmap |
| `POST /api/ai/recommend-resources` | Recommend learning resources |

### Student Management
| Endpoint | Description |
|---|---|
| `GET /api/skills` | List student's skills (requires token) |
| `POST /api/skills` | Add a skill |
| `PUT /api/skills/{id}` | Update a skill |
| `DELETE /api/skills/{id}` | Delete a skill |
| `GET /api/careers` | List all careers |
| `GET /api/careers/{id}` | Get career details |
| `GET /api/progress` | Get learning progress (requires token) |
| `POST /api/progress/{id}` | Update task progress |

### Demo Mode
- `GET /api/demo-mode` - Check if running in demo mode

## Database Schema

### Key Tables

**users** - User accounts
- id (PK), email (unique), username (unique), hashed_password
- is_active, is_superuser, created_at

**student_profiles** - Student profile information
- id (PK), user_id (FK → users), name, institution, degree
- academic_year, interests, learning_goals
- created_at, updated_at (trigger)

**student_skills** - Student's skills
- id (PK), user_id (FK → users), profile_id (FK → student_profiles)
- skill_name, proficiency_level, category
- created_at

**careers** - Career paths
- id (PK), name (unique), description, category
- average_salary, growth_outlook, created_at

**career_required_skills** - Skills required for each career
- id (PK), career_id (FK → careers), skill_name
- proficiency_required, importance_weight (1-5)
- created_at

**learning_roadmaps** - Personalized learning roadmaps
- id (PK), user_id (FK → users), career_id (FK → careers)
- title, description, version, ai_provider, ai_model
- created_at, updated_at (trigger)

**roadmap_phases** - Phases within a roadmap
- id (PK), roadmap_id (FK → learning_roadmaps)
- phase_name, phase_order, description, estimated_duration

**roadmap_tasks** - Tasks within phases
- id (PK), phase_id (FK → roadmap_phases)
- task_name, task_description, skill_focus
- estimated_duration, order_index, completion_criteria

**task_progress** - Task completion tracking
- id (PK), user_id (FK → users), task_id (FK → roadmap_tasks)
- status (completed/in_progress/not_started), completed_at, updated_at

**career_recommendations** - AI-generated career recommendations
- id (PK), user_id (FK → users), career_id (FK → careers)
- match_score (0-100), reason, matching_skills (JSON), missing_skills (JSON)
- ai_provider, ai_model, created_at

**skill_gap_analyses** - Skill gap analysis results
- id (PK), user_id (FK → users), career_id (FK → careers)
- match_percentage (0-100), existing_skills (JSON), required_skills (JSON)
- missing_skills (JSON), identified_skills (JSON), ai_provider, ai_model, created_at

**learning_resources** - Recommended learning resources
- id (PK), task_id (FK → roadmap_tasks)
- resource_name, platform, description, resource_type, url
- estimated_learning_duration, is_verified (default false), ai_provider, created_at

## Migration Commands

### Create Fresh Database
```bash
# Create database
createdb upskilling

# Apply all migrations
cd backend
/opt/homebrew/bin/python3 -c "
import os
os.environ['DATABASE_URL'] = 'postgresql://localhost:5432/upskilling'
from alembic.config import Config
config = Config('alembic.ini')
command.upgrade(config, 'head')
" || alembic upgrade head
```

### Generate New Migration
```bash
cd backend
/opt/homebrew/bin/python3 -m alembic revision --autogenerate -m "description of changes"
/opt/homebrew/bin/python3 -m alembic upgrade head
```

### Rollback Migration
```bash
cd backend
/opt/homebrew/bin/python3 -m alembic downgrade -1
```

## Flutter Commands

### Run on macOS
```bash
cd .freebuff/flutter_upskilling
flutter run  # or: flutter run -d macos
```

### Build Release
```bash
cd .freebuff/flutter_upskilling
flutter build macos --release
flutter build ios --release
flutter build web --release
```

### Analyze for Errors
```bash
cd .freebuff/flutter_upskilling
flutter analyze
flutter clean && flutter pub get && flutter analyze
```

## Testing

### Backend Tests
```bash
cd backend
/opt/homebrew/bin/python3 -m pytest tests/ -v
```

### Flutter Tests
```bash
cd .freebuff/flutter_upskilling
/opt/homebrew/bin/flutter test
```

### API Testing
Use curl or Postman:
```bash
# Health check
curl http://localhost:8000/health

# Authentication
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "username": "testuser", "password": "password123"}'

curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "password123"}'
```

## Directory Structure

```
AI-Upskilling-Recommendation-System/
├── README.md                    # This file
├── docs/
│   └── SRS.md                   # Software Requirements Specification
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI app with all routes
│   │   ├── core/config.py      # Settings with AI provider config
│   │   ├── database/           # SQLAlchemy models + connection
│   │   │   ├── models.py       # All 13 SQLAlchemy models
│   │   │   └── connection.py   # DATABASE_URL from env
│   │   ├── services/ai/        # AI provider abstraction
│   │   │   ├── service.py      # Shared AI service
│   │   │   ├── providers/      # Gemini/Ollama/Compatible
│   │   │   │   ├── base.py     # AIProvider base class
│   │   │   │   ├── gemini.py   # Gemini provider
│   │   │   │   ├── ollama.py   # Ollama provider
│   │   │   │   └── compatible.py  # Compatible provider
│   │   ├── api/                # All REST API endpoints
│   │   ├── models.py           # SQLAlchemy Base
│   │   └── services/           # Business logic
│   ├── requirements.txt        # Python deps (no Flutter packages)
│   ├── alembic.ini             # Migration config
│   └── migrations/
│       └── versions/
│           └── 9a8c7ac117d4_*.py  # Initial schema migration
└── .freebuff/
    └── flutter_upskilling/
        ├── lib/
        │   ├── main.dart       # GoRouter (16 routes)
        │   ├── screens/        # All 16 screens
        │   │   ├── splash_screen.dart
        │   │   ├── onboarding_screen.dart
        │   │   ├── registration_screen.dart
        │   │   ├── login_screen.dart
        │   │   ├── dashboard_screen.dart
        │   │   ├── student_profile_screen.dart
        │   │   ├── skill_management_screen.dart
        │   │   ├── career_recommendations_screen.dart
        │   │   ├── career_details_screen.dart
        │   │   ├── skill_gap_analysis_screen.dart
        │   │   ├── personalized_skill_suggestions_screen.dart
        │   │   ├── learning_roadmap_screen.dart
        │   │   ├── roadmap_task_details_screen.dart
        │   │   ├── learning_resources_screen.dart
        │   │   ├── progress_tracking_screen.dart
        │   │   └── settings_screen.dart
        │   └── widgets/          # Reusable components
        │       ├── app_bar.dart
        │       ├── loading_indicator.dart
        │       └── error_message.dart
        ├── pubspec.yaml         # Flutter dependencies
        └── analysis_options.yaml
```

## AI Provider Architecture

The application uses a **shared AI service** with a **provider abstraction** so that switching between Gemini and Ollama (or any compatible provider) requires only configuration changes, not code changes.

### Provider Interface (`AIProvider` base class)
All providers implement:
- `generate(prompt, response_model?) → Any` - Generate text response
- `health_check() → bool` - Check provider availability

### Concrete Providers

**GeminiProvider** - Google Generative AI
- Reads API key from `AI_API_KEY` environment variable
- Reads model name from `AI_MODEL` configuration
- Supports structured JSON responses when available
- Handles timeouts and rate limits with bounded retries

**OllamaProvider** - Local LLM via Ollama
- Default base URL: `http://localhost:11434`
- Configurable model name via `AI_MODEL`
- No API key required
- Connection health checks
- Automatic retries on connection errors

**CompatibleProvider** - OpenAI-style APIs
- Configurable base URL via `AI_BASE_URL`
- Configurable API key via `AI_API_KEY`
- Configurable model via `AI_MODEL`
- Supports chat completions endpoint

### Demo Mode
When `AI_API_KEY` is empty or provider fails:
- Application continues in demo mode
- Structured mock responses with `demo_mode: true` flag
- Clearly labeled demo/mock data in all responses
- Non-AI features remain fully functional
- Users see meaningful messages about AI unavailability

## Security

- **Never hardcode API keys** - all credentials via environment variables
- **Password hashing** with bcrypt (via passlib)
- **JWT tokens** with 30-minute expiration (configurable)
- **User ownership checks** on all protected endpoints
- **One student cannot access another's data** by ID manipulation
- **CORS configured** for safe development (restrict for production)
- **Input validation** with Pydantic schemas on all endpoints

## Known Limitations

- **Flutter-FastAPI integration**: Requires running backend server; CORS may need adjustment for production origins
- **AI provider**: Demo mode works without API key; Gemini/Ollama require proper setup
- **Database**: PostgreSQL must be running and accessible via `DATABASE_URL`
- **Ollama**: Requires local installation and at least one model pulled (`ollama pull llama2` etc.)

## Future Enhancements

- Real-time progress syncing
- Offline mode with local caching
- Social features (study groups, progress sharing)
- Additional AI models and providers
- Advanced analytics and reporting
- Push notifications for progress milestones
- Multi-language support