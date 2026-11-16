# Software Architecture Specification

## Project #22: AI-Powered Upskilling Recommendation and Automation System for Students
**Team 28 — CODEVERSE**  
**Course:** Software Engineering (Sem 5), PES University  
**Document Version:** 2.0 (Updated Post-Sprint with Multi-AI Provider & Key Security Architecture)

---

## 1. High-Level Architecture Diagram

The system employs a **Layered Modular Monolith Architecture** designed to maximize separation of concerns, testability, and security while keeping deployment simple for university evaluation and production scalability.

![AI Upskilling System Architecture](architecture_diagram.svg)

---

## 2. Interactive Mermaid Architecture Views

### 2.1 System Architecture & Layered Interaction

```mermaid
flowchart TD
    subgraph Layer1["1. Presentation Layer (Flutter 3.x Web & Desktop)"]
        UI_Auth["Authentication\n(Login / Register / Onboarding)"]
        UI_Profile["Student Profile\n(Academic Details & Bio)"]
        UI_Skills["Skills Portfolio\n(CRUD & Proficiency Levels)"]
        UI_Rec["AI Recommendations & Gap\n(Career Matches & Gap Analysis)"]
        UI_Roadmap["Roadmaps & Progress\n(Weekly Milestones & Checklists)"]
        UI_Settings["Settings & Platform Config\n(Multi-Provider & Key Management)"]
    end

    subgraph Layer2["2. API & Controller Layer (FastAPI / Uvicorn)"]
        GW["API Gateway & Middleware\n(CORS / OAuth2 Bearer / Error Handling)"]
        R_Auth["Auth Router\n(/api/auth/*)"]
        R_Profile["Profile Router\n(/api/profile/*)"]
        R_Skills["Skills Router\n(/api/skills/*)"]
        R_Rec["Career & Gap Router\n(/api/recommendations/*)"]
        R_Roadmap["Roadmap & Progress Router\n(/api/roadmaps/*)"]
        R_AI["AI Provider & Key Router\n(/api/ai/*, /api/settings/*)"]
    end

    subgraph Layer3["3. AI & Domain Service Layer"]
        AIService["AIService Orchestrator\n(Strategy Pattern & Prompt Engineering)"]
        Gemini["Google Gemini Provider\n(Cloud Generative AI)"]
        Ollama["Ollama Provider\n(Local Private LLMs: localhost:11434)"]
        Compatible["OpenAI-Compatible Provider\n(Groq / Together / vLLM)"]
        Fallback["Deterministic Rule Engine\n(TF-IDF / Cosine Similarity Fallback)"]
        Crypto["Fernet AES-256 Vault\n(At-Rest API Key Encryption)"]
    end

    subgraph Layer4["4. Persistence Layer (SQLAlchemy ORM)"]
        DB[(Database Engine\nSQLite dev / PostgreSQL prod)]
        T_Users["users & student_profiles"]
        T_Skills["skills & student_skills"]
        T_Careers["careers & career_skills"]
        T_Recs["career_recommendations"]
        T_Roadmaps["learning_roadmaps, items & progress"]
    end

    %% Connections
    Layer1 -->|HTTP REST / JSON / Bearer JWT| GW
    GW --> R_Auth
    GW --> R_Profile
    GW --> R_Skills
    GW --> R_Rec
    GW --> R_Roadmap
    GW --> R_AI

    R_Rec --> AIService
    R_AI --> AIService
    R_AI --> Crypto
    R_Roadmap --> AIService

    AIService --> Gemini
    AIService --> Ollama
    AIService --> Compatible
    AIService --> Fallback

    R_Auth --> T_Users
    R_Profile --> T_Users
    R_Skills --> T_Skills
    R_Rec --> T_Careers
    R_Rec --> T_Recs
    R_Roadmap --> T_Roadmaps

    T_Users --- DB
    T_Skills --- DB
    T_Careers --- DB
    T_Recs --- DB
    T_Roadmaps --- DB
```

---

### 2.2 End-to-End Student Workflow Sequence

```mermaid
sequenceDiagram
    autonumber
    actor Student as Student (Browser)
    participant UI as Flutter Frontend
    participant API as FastAPI Backend
    participant AI as AIService Orchestrator
    participant LLM as Active AI Provider (Gemini/Ollama)
    participant DB as SQLite / PostgreSQL Database

    Note over Student, UI: Authentication & Profiling
    Student->>UI: Enters Credentials (Email & Password)
    UI->>API: POST /api/auth/login
    API->>DB: Query User & Validate BCrypt Hash
    DB-->>API: User Record
    API-->>UI: 200 OK + JWT Bearer Token

    Note over Student, UI: Skill Registration & Career Matching
    Student->>UI: Adds Current Skills (e.g. Python, SQL)
    UI->>API: POST /api/skills (with Bearer Token)
    API->>DB: Save Student Skills
    DB-->>API: Confirmation

    Student->>UI: Requests Career Recommendations
    UI->>API: POST /api/recommendations
    API->>DB: Fetch Student Skills & Career Benchmarks
    DB-->>API: Skill Matrix & Profile Context
    API->>AI: generate_recommendations(profile, skills)
    alt Live AI Provider Active
        AI->>LLM: Formatted Prompt with Context & Schemas
        LLM-->>AI: Ranked Careers with Match Reasoning
    else Fallback / Offline Demo Mode
        AI->>AI: Compute Similarity Matrix & Rule Scoring
    end
    AI-->>API: Normalized Recommendations JSON
    API->>DB: Persist CareerRecommendation Logs
    API-->>UI: 200 OK + Ranked Recommendations

    Note over Student, UI: Skill Gap & Learning Roadmap
    Student->>UI: Selects Career (e.g. Data Scientist)
    UI->>API: GET /api/careers/{id}/gap
    API-->>UI: Missing Competencies & Proficiency Deficits
    Student->>UI: Generates Learning Roadmap
    UI->>API: POST /api/roadmaps
    API->>AI: generate_roadmap(target_career, missing_skills)
    AI-->>API: Milestone Curriculum & Resources
    API->>DB: Save LearningRoadmap & RoadmapItems
    API-->>UI: 200 OK + Structured Milestone Roadmap
```

---

### 2.3 AI Provider Strategy Pattern (Class Architecture)

```mermaid
classDiagram
    class AIService {
        -BaseAIProvider _provider
        -str _provider_type
        -str _model
        -bool _demo_mode
        +get_provider_info() dict
        +set_provider(provider_type: str)
        +generate_recommendations(skills, profile) list
        +analyze_skill_gap(career, current_skills) dict
        +generate_roadmap(career, gaps) dict
    }

    class BaseAIProvider {
        <<abstract>>
        +str model
        +bool is_configured
        +generate(prompt: str)* str
        +test_connection()* bool
    }

    class GeminiProvider {
        -genai.GenerativeModel _model
        -str api_key
        +generate(prompt: str) str
        +test_connection() bool
    }

    class OllamaProvider {
        -str base_url
        -str model_name
        +generate(prompt: str) str
        +test_connection() bool
    }

    class OpenAICompatibleProvider {
        -str base_url
        -str api_key
        +generate(prompt: str) str
        +test_connection() bool
    }

    class DeterministicFallbackEngine {
        -dict career_taxonomy
        +calculate_match_score(skills, career) float
        +find_missing_skills(skills, career) list
        +generate_fallback_roadmap(gaps) dict
    }

    AIService --> BaseAIProvider : delegates to
    AIService --> DeterministicFallbackEngine : fallback on failure
    BaseAIProvider <|-- GeminiProvider : implements
    BaseAIProvider <|-- OllamaProvider : implements
    BaseAIProvider <|-- OpenAICompatibleProvider : implements
```

---

### 2.4 Entity-Relationship (ER) Schema

```mermaid
erDiagram
    users ||--o| student_profiles : "has"
    users ||--o{ student_skills : "owns"
    users ||--o{ learning_roadmaps : "creates"
    users ||--o{ task_progress : "records"
    users ||--o{ career_recommendations : "receives"

    skills ||--o{ student_skills : "categorizes"
    skills ||--o{ career_skills : "required_in"

    careers ||--o{ career_skills : "demands"
    careers ||--o{ career_recommendations : "suggested_as"
    careers ||--o{ learning_roadmaps : "targets"

    learning_roadmaps ||--o{ roadmap_items : "contains"
    roadmap_items ||--o{ learning_resources : "references"
    roadmap_items ||--o{ task_progress : "tracked_by"

    users {
        int id PK
        string email UK
        string username UK
        string hashed_password
        boolean is_active
        datetime created_at
        string api_key "Encrypted at rest"
    }

    student_profiles {
        int id PK
        int user_id FK
        string name
        string degree
        string graduation_year
        string bio
        string target_career
    }

    skills {
        int id PK
        string skill_name UK
        string category
        string description
    }

    student_skills {
        int id PK
        int user_id FK
        int skill_id FK
        string proficiency_level
        datetime created_at
    }

    careers {
        int id PK
        string career_title UK
        string description
        string industry
    }

    career_skills {
        int id PK
        int career_id FK
        int skill_id FK
        string required_level
        float importance_weight
    }

    career_recommendations {
        int id PK
        int user_id FK
        int career_id FK
        float match_percentage
        string reasoning
        string ai_provider
        datetime created_at
    }

    learning_roadmaps {
        int id PK
        int user_id FK
        int career_id FK
        string roadmap_title
        int duration_weeks
        datetime created_at
    }

    roadmap_items {
        int id PK
        int roadmap_id FK
        int week_number
        string milestone_title
        string description
        string status
    }

    learning_resources {
        int id PK
        int roadmap_item_id FK
        string resource_title
        string resource_type
        string resource_url
    }

    task_progress {
        int id PK
        int user_id FK
        int roadmap_item_id FK
        string status
        datetime completed_at
    }
```

---

## 3. Detailed Layer Descriptions

### 3.1 Presentation Layer (Frontend)
- **Technology:** Flutter 3.x (compiled for Web and Windows Desktop) using Dart.
- **Navigation:** Declarative routing configured via `GoRouter` with protected authentication redirects (`/login`, `/register`, `/dashboard`, `/profile`, `/skills`, `/career-recommendations`, `/skill-gap`, `/roadmap`, `/progress`, `/settings`).
- **State Management & Services:** 
  - `APIClient` handles all HTTP communication, automatic JWT header injection, error deserialization, and token caching via `SharedPreferences`.
- **UI Design System:** Standardized Material 3 palette (`AppColors`, `AppCard`, `StatusPill`, `PageContainer`) ensuring accessible contrast and responsive multi-column layouts across desktop and mobile form factors.

### 3.2 API Gateway & Controller Layer (Backend)
- **Technology:** FastAPI running on the high-performance Uvicorn ASGI server.
- **Middleware & Security:**
  - `CORSMiddleware`: Secure cross-origin resource sharing supporting wildcard localhost ports for dynamic Flutter Web builds.
  - `OAuth2PasswordBearer`: Authentication route protection using RFC-standard Bearer tokens.
  - `passlib[bcrypt]`: Salted, one-way password hashing protecting user credentials.
- **API Endpoints:**
  - `/api/auth/*`: Registration, login, and JWT validation.
  - `/api/profile/*`: Student demographic, academic degree, and target aspiration management.
  - `/api/skills/*`: Case-insensitive skill portfolio management (`Beginner`, `Intermediate`, `Advanced`).
  - `/api/recommendations/*`: ML and AI-driven career matching.
  - `/api/careers/{id}/gap`: Gap comparison between user competencies and industry requirements.
  - `/api/roadmaps/*`: Structured sequential curricula generation and milestone tracking.
  - `/api/settings/*` & `/api/ai/*`: Dynamic AI provider selection, health probes, and at-rest key encryption.

### 3.3 AI Intelligence & Business Logic Layer
- **Strategy Pattern (`AIService`):** Decouples user-facing recommendation workflows from underlying AI model vendors.
- **Supported Providers:**
  1. **Google Gemini:** Cloud LLM (`gemini-3-flash-preview` / `gemini-pro`) for high-reasoning synthesis.
  2. **Ollama:** Self-hosted local inference (`localhost:11434`, `llama3.2`, `mistral`) for zero-cost, fully private processing without external API keys.
  3. **OpenAI-Compatible:** Universal adapter supporting open-weight hosted APIs (Groq, Together AI, vLLM).
- **Security & Privacy:**
  - Fernet symmetric AES-256 encryption (`app/services/encryption.py`) encrypts API keys before storing them in the database.
  - Keys are never serialized to the frontend or written to server logs.
- **Deterministic Fallback Engine:** Rule-based heuristic matrix ensuring 100% test reliability and graceful demo mode execution even without network access or valid API credentials.

### 3.4 Data Persistence Layer
- **ORM:** SQLAlchemy 2.0 with strongly typed models.
- **Storage Engines:** SQLite (`upskilling.db`) for lightweight local development; seamless compatibility with PostgreSQL for production.
- **Migration & Integrity:** Self-healing auto-migration hooks on server startup (`Base.metadata.create_all` with schema-safe column alterations) and Alembic versioning.

---

## 4. Team Ownership & Responsibilities

| Member | Primary Architecture Ownership | Key Modules Owned |
| :--- | :--- | :--- |
| **Member 1 (Current User)** | **AI Provider Selection & Architecture** | `SettingsScreen` Provider Selection Dialog, Supported Provider Catalog, Active Provider Showcase Card, `set_provider()` API |
| **Member 2** | **AI Model Selection** | Dynamic model listing, provider-compatible model persistence, active model runtime synchronization |
| **Member 3** | **Secure API Key Configuration** | Fernet AES-256 at-rest key encryption, authenticated `/api/ai/api-key` endpoint, masked client key configuration |
| **Member 4** | **Notification Preferences** | User alert preferences, notification persistence, and system delivery rules |

---

## 5. Architectural Quality Attributes

- **Modularity:** High cohesion within modules (Auth, Skills, AI, Roadmap) and low coupling via clear REST endpoints.
- **Security:** Zero plaintext secret storage, HTTPS-ready architecture, parameterized SQL queries preventing injection, and robust CORS preflight protection.
- **Resilience:** Multi-tier fallback strategy guarantees continuous application uptime even during third-party AI downtime or quota exhaustion.
- **Portability:** Container-ready Python backend and cross-platform Flutter frontend that compiles identically to Web, Windows, macOS, and Linux.
