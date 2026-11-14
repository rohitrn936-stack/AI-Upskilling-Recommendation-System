from fastapi import FastAPI, HTTPException, Depends, status, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
import os
import uvicorn

from app.database.connection import SessionLocal, engine
from app.database.models import Base
from app.core.config import settings
from app.services.ai.service import AIService

# Initialize AI service
ai_service = AIService()

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Password hashing
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)
def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

# JWT imports and utility
from jose import jwt as jose_jwt
import datetime
from datetime import datetime, timedelta, timezone

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=int(settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    encoded_jwt = jose_jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm="HS256")
    return encoded_jwt
def decode_access_token(token: str):
    try:
        payload = jose_jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=["HS256"])
        return payload
    except jose_jwt.ExpiredSignatureError:
        return None
    except jose_jwt.JWTError:
        return None
def get_current_user(db: Session, token: str):
    payload = decode_access_token(token)
    if payload is None:
        return None
    username: str = payload.get("sub")
    if username is None:
        return None
    from app.database.models import User
    user = db.query(User).filter(User.username == username).first()
    return user

def get_current_user_dependency(db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)):
    user = get_current_user(db, token)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )
    return user

# Create FastAPI app FIRST
app = FastAPI(
    title="AI-Powered Upskilling Recommendation System",
    description="Intelligent application that helps students identify suitable career opportunities based on their existing skills",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
)

# CORS middleware - AFTER app creation
# Configure allowed origins via environment variable for security
# Format: comma-separated list, e.g., "http://localhost:3000,http://localhost:8080"
allowed_origins_str = os.environ.get("CORS_ORIGINS") or settings.CORS_ORIGINS
if allowed_origins_str:
    allow_origins = [origin.strip() for origin in allowed_origins_str.split(",") if origin.strip()]
else:
    # Default to localhost for development
    allow_origins = ["http://localhost:3000", "http://127.0.0.1:3000"]

allow_origin_regex = (
    r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"
    if settings.ENVIRONMENT == "development"
    else None
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_origin_regex=allow_origin_regex,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure database tables exist on startup
Base.metadata.create_all(bind=engine)

# Now define Pydantic schemas and routes...

# AI endpoints with Pydantic request validation
from pydantic import BaseModel, Field
from typing import List, Dict, Optional

# Request/response schemas for career recommendations
class CareerRecommendationRequest(BaseModel):
    skills: List[str] = Field(default_factory=list, description="List of student skills")
    proficiency: Dict[str, str] = Field(default_factory=dict, description="Proficiency levels per skill")
    interests: str = Field(default="", description="Student's interests")
    academic_background: str = Field(default="", description="Student's academic background")

class CareerRecommendationResponse(BaseModel):
    success: bool
    data: Optional[dict] = None

@app.post("/api/ai/career-recommendations", response_model=CareerRecommendationResponse)
async def career_recommendations(request: CareerRecommendationRequest, current_user = Depends(get_current_user_dependency), db: Session = Depends(get_db)):
    """Get career recommendations based on student skills."""
    try:
        from app.database.models import User

        recommendations = await ai_service.get_career_recommendations(
            skills=request.skills,
            proficiency_levels=request.proficiency,
            interests=request.interests,
            academic_background=request.academic_background,
        )
        return {"success": True, "data": recommendations}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate career recommendations: {str(e)}",
        )

# Request/response schemas for skill gap analysis
class SkillGapAnalysisRequest(BaseModel):
    student_skills: List[Dict[str, str]] = Field(default_factory=list, description="Student's skills with proficiency")
    required_skills: List[Dict[str, str]] = Field(default_factory=list, description="Required skills for career")

class SkillGapAnalysisResponse(BaseModel):
    success: bool
    data: Optional[dict] = None

@app.post("/api/ai/skill-gap-analysis", response_model=SkillGapAnalysisResponse)
async def skill_gap_analysis(request: SkillGapAnalysisRequest, current_user = Depends(get_current_user_dependency), db: Session = Depends(get_db)):
    """Analyze skill gaps between student skills and career requirements."""
    try:
        analysis = await ai_service.analyze_skill_gap(
            student_skills=request.student_skills,
            required_skills=request.required_skills,
        )
        return {"success": True, "data": analysis}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to analyze skill gap: {str(e)}",
        )

# Request/response schemas for personalized skills
class PersonalizedSkillsRequest(BaseModel):
    existing_skills: List[str] = Field(default_factory=list, description="Student's current skills")
    target_career: str = Field(default="", description="Target career path")
    missing_skills: List[str] = Field(default_factory=list, description="Identified missing skills")
    learning_goals: str = Field(default="", description="Student's learning goals")

class PersonalizedSkillsResponse(BaseModel):
    success: bool
    data: Optional[dict] = None

@app.post("/api/ai/personalized-skills", response_model=PersonalizedSkillsResponse)
async def personalized_skills(request: PersonalizedSkillsRequest, current_user = Depends(get_current_user_dependency), db: Session = Depends(get_db)):
    """Get personalized skill suggestions."""
    try:
        suggestions = await ai_service.generate_personalized_skills(
            existing_skills=request.existing_skills,
            target_career=request.target_career,
            missing_skills=request.missing_skills,
            learning_goals=request.learning_goals,
        )
        return {"success": True, "data": suggestions}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate personalized skills: {str(e)}",
        )

# Request/response schemas for roadmap generation
class RoadmapGenerateRequest(BaseModel):
    student_skills: List[Dict[str, str]] = Field(default_factory=list, description="Student's current skills")
    career_requirements: List[Dict[str, str]] = Field(default_factory=list, description="Required skills for target career")
    interests: str = Field(default="", description="Student's interests")
    academic_background: str = Field(default="", description="Student's academic background")
    learning_goals: str = Field(default="", description="Student's learning goals")

class RoadmapGenerateResponse(BaseModel):
    success: bool
    data: Optional[dict] = None

@app.post("/api/ai/roadmap-generate", response_model=RoadmapGenerateResponse)
async def generate_roadmap(request: RoadmapGenerateRequest, current_user = Depends(get_current_user_dependency), db: Session = Depends(get_db)):
    """Generate and persist a personalized learning roadmap."""
    from app.database.models import LearningRoadmap, RoadmapPhase, RoadmapTask, TaskProgress

    try:
        generated = await ai_service.generate_learning_roadmap(
            student_skills=request.student_skills,
            career_requirements=request.career_requirements,
            interests=request.interests,
            academic_background=request.academic_background,
            learning_goals=request.learning_goals,
        )

        roadmap_payload = generated.get("roadmap") if isinstance(generated, dict) and isinstance(generated.get("roadmap"), dict) else generated
        phases_data = roadmap_payload.get("phases", []) if isinstance(roadmap_payload, dict) else []
        title = str((roadmap_payload.get("title") if isinstance(roadmap_payload, dict) else None) or "Personalized Learning Roadmap")

        roadmap_record = LearningRoadmap(
            user_id=current_user.id,
            title=title,
            description=str(request.learning_goals or "AI-generated upskilling roadmap"),
            ai_provider=settings.AI_PROVIDER,
            ai_model=settings.AI_MODEL or None,
        )
        db.add(roadmap_record)
        db.flush()

        def _as_text(val, default=""):
            if val is None:
                return default
            if isinstance(val, list):
                joined = "; ".join(str(x).strip() for x in val if str(x).strip())
                return joined or default
            if isinstance(val, dict):
                return ", ".join(f"{k}: {v}" for k, v in val.items()) or default
            s = str(val).strip()
            return s or default

        saved_phases = []
        for p_idx, phase in enumerate(phases_data, start=1):
            phase_record = RoadmapPhase(
                roadmap_id=roadmap_record.id,
                phase_name=_as_text(phase.get("phase_name"), f"Phase {p_idx}"),
                phase_order=int(phase.get("phase_order", p_idx) or p_idx),
                description=_as_text(phase.get("description"), ""),
                estimated_duration=_as_text(phase.get("estimated_duration"), ""),
            )
            db.add(phase_record)
            db.flush()

            tasks_data = phase.get("tasks") or []
            if not tasks_data:
                tasks_data = [
                    {
                        "task_name": f"Complete {phase_record.phase_name}",
                        "description": phase_record.description or "Study core topics in this phase",
                        "skill_focus": phase_record.phase_name,
                        "estimated_duration": phase_record.estimated_duration or "2 weeks",
                        "completion_criteria": "Complete phase exercises",
                    }
                ]

            saved_tasks = []
            for t_idx, task in enumerate(tasks_data, start=1):
                task_record = RoadmapTask(
                    phase_id=phase_record.id,
                    task_name=_as_text(task.get("task_name"), f"Task {t_idx}"),
                    task_description=_as_text(task.get("description") or task.get("task_description"), ""),
                    skill_focus=_as_text(task.get("skill_focus"), ""),
                    estimated_duration=_as_text(task.get("estimated_duration"), ""),
                    order_index=t_idx,
                    completion_criteria=_as_text(task.get("completion_criteria"), ""),
                )
                db.add(task_record)
                db.flush()

                progress_record = TaskProgress(
                    user_id=current_user.id,
                    task_id=task_record.id,
                    status="not_started",
                )
                db.add(progress_record)
                saved_tasks.append({
                    "id": task_record.id,
                    "task_name": task_record.task_name,
                    "task_description": task_record.task_description,
                    "skill_focus": task_record.skill_focus,
                    "estimated_duration": task_record.estimated_duration,
                    "completion_criteria": task_record.completion_criteria,
                    "status": "not_started",
                })

            saved_phases.append({
                "id": phase_record.id,
                "phase_name": phase_record.phase_name,
                "phase_order": phase_record.phase_order,
                "description": phase_record.description,
                "estimated_duration": phase_record.estimated_duration,
                "tasks": saved_tasks,
            })

        db.commit()
        return {
            "success": True,
            "data": {
                "demo_mode": bool(generated.get("demo_mode")) if isinstance(generated, dict) else False,
                "roadmap": {
                    "id": roadmap_record.id,
                    "title": roadmap_record.title,
                    "description": roadmap_record.description,
                    "phases": saved_phases,
                },
            },
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate learning roadmap: {str(e)}",
        )


@app.get("/api/roadmap")
async def get_latest_roadmap(
    current_user = Depends(get_current_user_dependency),
    db: Session = Depends(get_db),
):
    """Get the student's latest saved learning roadmap with task progress."""
    from app.database.models import LearningRoadmap, TaskProgress

    roadmaps_query = db.query(LearningRoadmap).filter(LearningRoadmap.user_id == current_user.id)
    roadmap_count = roadmaps_query.count()
    roadmap = roadmaps_query.order_by(LearningRoadmap.id.desc()).first()

    if not roadmap:
        return {"success": True, "data": {"roadmap": None, "roadmap_count": 0}}

    progress_rows = db.query(TaskProgress).filter(TaskProgress.user_id == current_user.id).all()
    progress_by_task = {p.task_id: p.status for p in progress_rows}

    phases_out = []
    for phase in sorted(roadmap.phases, key=lambda p: p.phase_order):
        tasks_out = []
        for task in sorted(phase.tasks, key=lambda t: t.order_index):
            tasks_out.append({
                "id": task.id,
                "task_name": task.task_name,
                "task_description": task.task_description or "",
                "skill_focus": task.skill_focus or "",
                "estimated_duration": task.estimated_duration or "",
                "completion_criteria": task.completion_criteria or "",
                "status": progress_by_task.get(task.id, "not_started"),
            })
        phases_out.append({
            "id": phase.id,
            "phase_name": phase.phase_name,
            "phase_order": phase.phase_order,
            "description": phase.description or "",
            "estimated_duration": phase.estimated_duration or "",
            "tasks": tasks_out,
        })

    return {
        "success": True,
        "data": {
            "roadmap_count": roadmap_count,
            "roadmap": {
                "id": roadmap.id,
                "title": roadmap.title,
                "description": roadmap.description or "",
                "phases": phases_out,
            },
        },
    }

# Request/response schemas for resource recommendations
class ResourceRecommendationRequest(BaseModel):
    task_description: str = Field(..., description="Description of the task or skill to learn")
    skill_focus: str = Field(default="", description="The skill the resources focus on")
    resource_type: str = Field(default="mixed", description="Type of resources (video, article, course, book, mixed)")

class ResourceRecommendationResponse(BaseModel):
    success: bool
    data: Optional[dict] = None

@app.post("/api/ai/recommend-resources", response_model=ResourceRecommendationResponse)
async def recommend_resources(request: ResourceRecommendationRequest, current_user = Depends(get_current_user_dependency), db: Session = Depends(get_db)):
    """Recommend learning resources for a task."""
    try:
        resources = await ai_service.recommend_learning_resources(
            task_description=request.task_description,
            skill_focus=request.skill_focus,
            resource_type=request.resource_type,
        )
        return {"success": True, "data": resources}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to recommend learning resources: {str(e)}",
        )

# ============ AUTHENTICATION ENDPOINTS ============

@app.post("/api/auth/register")
async def register(
    email: str = Form(...),
    username: str = Form(...),
    password: str = Form(...),
    db: Session = Depends(get_db),
):
    """User registration with password hashing."""
    from app.database.models import User

    # Check if user already exists
    existing_user = db.query(User).filter(
        (User.email == email) | (User.username == username)
    ).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email or username already registered",
        )

    # Create new user with hashed password
    hashed_password = get_password_hash(password)
    new_user = User(
        email=email,
        username=username,
        hashed_password=hashed_password,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {"success": True, "data": {"id": new_user.id, "email": new_user.email, "username": new_user.username}}

@app.post("/api/auth/login")
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    """User login with JWT token."""
    from app.database.models import User

    # Find user by username or email
    user = db.query(User).filter(
        (User.username == form_data.username) | (User.email == form_data.username)
    ).first()

    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Create access token
    access_token = create_access_token(
        data={"sub": user.username}
    )

    return {"success": True, "data": {"access_token": access_token, "token_type": "bearer"}}

# ============ PROTECTED ENDPOINTS ============

# Profile schemas
class ProfileUpdateRequest(BaseModel):
    name: Optional[str] = None
    institution: Optional[str] = None
    degree: Optional[str] = None
    academic_year: Optional[str] = None
    interests: Optional[str] = None
    learning_goals: Optional[str] = None

@app.get("/api/profile")
async def get_profile(
    current_user = Depends(get_current_user_dependency),
    db: Session = Depends(get_db),
):
    """Get current student profile."""
    from app.database.models import StudentProfile, StudentSkill

    profile = db.query(StudentProfile).filter(StudentProfile.user_id == current_user.id).first()
    user_skills = db.query(StudentSkill).filter(StudentSkill.user_id == current_user.id).all()

    if not profile:
        # Return default profile if none exists
        return {
            "success": True,
            "data": {
                "name": current_user.username,
                "email": current_user.email,
                "institution": "",
                "degree": "",
                "academic_year": "",
                "interests": "",
                "learning_goals": "",
                "skills": [skill.skill_name for skill in user_skills],
            },
        }

    return {"success": True, "data": {
        "id": profile.id,
        "name": profile.name or current_user.username,
        "email": current_user.email,
        "institution": profile.institution or "",
        "degree": profile.degree or "",
        "academic_year": profile.academic_year or "",
        "interests": profile.interests or "",
        "learning_goals": profile.learning_goals or "",
        "skills": [skill.skill_name for skill in user_skills],
    }}


@app.post("/api/profile")
async def update_profile(
    profile_data: ProfileUpdateRequest,
    current_user = Depends(get_current_user_dependency),
    db: Session = Depends(get_db),
):
    """Update student profile."""
    from app.database.models import StudentProfile

    profile = db.query(StudentProfile).filter(StudentProfile.user_id == current_user.id).first()

    if not profile:
        from datetime import datetime
        profile = StudentProfile(
            user_id=current_user.id,
            name=profile_data.name or current_user.username,
            institution=profile_data.institution or "",
            degree=profile_data.degree or "",
            academic_year=profile_data.academic_year or "",
            interests=profile_data.interests or "",
            learning_goals=profile_data.learning_goals or "",
        )
        db.add(profile)
    else:
        if profile_data.name is not None:
            profile.name = profile_data.name
        if profile_data.institution is not None:
            profile.institution = profile_data.institution
        if profile_data.degree is not None:
            profile.degree = profile_data.degree
        if profile_data.academic_year is not None:
            profile.academic_year = profile_data.academic_year
        if profile_data.interests is not None:
            profile.interests = profile_data.interests
        if profile_data.learning_goals is not None:
            profile.learning_goals = profile_data.learning_goals

    db.commit()
    db.refresh(profile)

    return {"success": True, "data": {"message": "Profile updated successfully", "profile": {
        "id": profile.id,
        "name": profile.name,
        "institution": profile.institution,
        "degree": profile.degree,
        "academic_year": profile.academic_year,
        "interests": profile.interests,
        "learning_goals": profile.learning_goals,
    }}}

# Skill management endpoints
@app.get("/api/skills")
async def list_skills(
    current_user = Depends(get_current_user_dependency),
    db: Session = Depends(get_db),
):
    """List student's skills."""
    from app.database.models import StudentSkill

    skills = db.query(StudentSkill).filter(StudentSkill.user_id == current_user.id).all()
    skill_list = []
    for skill in skills:
        skill_list.append({
            "id": skill.id,
            "skill_name": skill.skill_name,
            "proficiency_level": skill.proficiency_level,
            "category": skill.category,
        })
    return {"success": True, "data": {"skills": skill_list}}

# Updated: add_skill now uses JSON request body with skill_name, proficiency_level, category
@app.post("/api/skills")
async def add_skill(
    skill_data: dict,
    current_user = Depends(get_current_user_dependency),
    db: Session = Depends(get_db),
):
    """Add a skill for the current user using JSON request body."""
    from app.database.models import StudentSkill

    skill_name = skill_data.get("skill_name", "") if isinstance(skill_data, dict) else ""
    proficiency_level = skill_data.get("proficiency_level", "beginner") if isinstance(skill_data, dict) else "beginner"
    category = skill_data.get("category", "") if isinstance(skill_data, dict) else ""

    if not skill_name:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="skill_name is required",
        )

    # Validate allowed proficiency levels
    valid_proficiencies = ["beginner", "intermediate", "advanced", "expert"]
    if proficiency_level not in valid_proficiencies:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid proficiency level '{proficiency_level}'. Allowed values: {', '.join(valid_proficiencies)}",
        )

    new_skill = StudentSkill(
        user_id=current_user.id,
        skill_name=skill_name,
        proficiency_level=proficiency_level,
        category=category,
    )
    db.add(new_skill)
    db.commit()

    return {"success": True, "data": {"message": f"Skill '{new_skill.skill_name}' added", "skill_id": new_skill.id}}

@app.put("/api/skills/{skill_id}")
async def update_skill(
    skill_id: int,
    skill_data: dict,
    current_user = Depends(get_current_user_dependency),
    db: Session = Depends(get_db),
):
    """Update a skill for the current user."""
    from app.database.models import StudentSkill

    skill = db.query(StudentSkill).filter(
        StudentSkill.id == skill_id,
        StudentSkill.user_id == current_user.id
    ).first()

    if not skill:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Skill not found",
        )

    if skill_data and isinstance(skill_data, dict):
        if "proficiency_level" in skill_data and skill_data["proficiency_level"]:
            skill.proficiency_level = skill_data["proficiency_level"]
        if "category" in skill_data and skill_data["category"]:
            skill.category = skill_data["category"]

    db.commit()

    return {"success": True, "data": {"message": f"Skill {skill_id} updated"}}

@app.delete("/api/skills/{skill_id}")
async def delete_skill(
    skill_id: int,
    current_user = Depends(get_current_user_dependency),
    db: Session = Depends(get_db),
):
    """Delete a skill for the current user."""
    from app.database.models import StudentSkill

    skill = db.query(StudentSkill).filter(
        StudentSkill.id == skill_id,
        StudentSkill.user_id == current_user.id
    ).first()

    if not skill:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Skill not found",
        )

    db.delete(skill)
    db.commit()

    return {"success": True, "data": {"message": f"Skill {skill_id} deleted"}}

# Career endpoints
@app.get("/api/careers")
async def list_careers(
    db: Session = Depends(get_db),
):
    """List available careers."""
    from app.database.models import Career

    careers = db.query(Career).all()
    return {"success": True, "data": {"careers": careers}}

@app.get("/api/careers/{career_id}")
async def get_career(
    career_id: int,
    db: Session = Depends(get_db),
):
    """Get career details."""
    from app.database.models import Career

    career = db.query(Career).filter(Career.id == career_id).first()
    if not career:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Career not found",
        )

    return {"success": True, "data": {
        "id": career.id,
        "name": career.name,
        "description": career.description,
        "category": career.category,
        "average_salary": career.average_salary,
        "growth_outlook": career.growth_outlook,
    }}

# Roadmap progress endpoints
@app.get("/api/progress")
async def get_progress(
    current_user = Depends(get_current_user_dependency),
    db: Session = Depends(get_db),
):
    """Get learning progress."""
    from app.database.models import TaskProgress, RoadmapTask, RoadmapPhase, LearningRoadmap

    roadmaps_query = db.query(LearningRoadmap).filter(LearningRoadmap.user_id == current_user.id)
    roadmap_count = roadmaps_query.count()
    latest_roadmap = roadmaps_query.order_by(LearningRoadmap.id.desc()).first()

    # Get all tasks across the user's roadmaps (or latest roadmap if present)
    progress_rows = db.query(TaskProgress).filter(TaskProgress.user_id == current_user.id).all()
    status_by_task = {t.task_id: t.status for t in progress_rows}

    if latest_roadmap:
        phase_summaries = []
        total_tasks = 0
        completed_tasks = 0
        for phase in sorted(latest_roadmap.phases, key=lambda p: p.phase_order):
            phase_tasks = phase.tasks
            phase_total = len(phase_tasks)
            phase_completed = sum(1 for task in phase_tasks if status_by_task.get(task.id) == "completed")
            total_tasks += phase_total
            completed_tasks += phase_completed
            phase_pct = int(phase_completed / phase_total * 100) if phase_total > 0 else 0
            phase_summaries.append({
                "phase_id": phase.id,
                "phase_name": phase.phase_name,
                "completed": phase_completed,
                "total": phase_total,
                "percentage": phase_pct,
            })
    else:
        phase_summaries = []
        total_tasks = db.query(RoadmapTask).join(RoadmapPhase).join(LearningRoadmap).filter(
            LearningRoadmap.user_id == current_user.id
        ).count()
        completed_tasks = sum(1 for t in progress_rows if t.status == "completed")

    percentage = int(completed_tasks / total_tasks * 100) if total_tasks > 0 else 0

    return {"success": True, "data": {
        "completed": completed_tasks,
        "total": total_tasks,
        "percentage": percentage,
        "roadmap_count": roadmap_count,
        "phases": phase_summaries,
        "task_details": [
            {"task_id": t.task_id, "status": t.status}
            for t in progress_rows
        ]
    }}

class ProgressUpdateRequest(BaseModel):
    status: str = Field(..., description="Task status (e.g., completed, in_progress)")

@app.post("/api/progress/{task_id}")
async def update_progress(
    task_id: int,
    progress_data: ProgressUpdateRequest,
    current_user = Depends(get_current_user_dependency),
    db: Session = Depends(get_db),
):
    """Update task progress with JSON body validation."""
    from app.database.models import TaskProgress, RoadmapTask, RoadmapPhase, LearningRoadmap

    progress = db.query(TaskProgress).filter(
        TaskProgress.user_id == current_user.id,
        TaskProgress.task_id == task_id
    ).first()

    if not progress:
        task_exists = (
            db.query(RoadmapTask)
            .join(RoadmapPhase)
            .join(LearningRoadmap)
            .filter(RoadmapTask.id == task_id, LearningRoadmap.user_id == current_user.id)
            .first()
        )
        if not task_exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Task {task_id} not found",
            )
        progress = TaskProgress(
            user_id=current_user.id,
            task_id=task_id,
            status=progress_data.status,
        )
        db.add(progress)

    progress.status = progress_data.status
    if progress_data.status == "completed":
        progress.completed_at = datetime.utcnow()
    else:
        progress.completed_at = None
    db.commit()

    return {"success": True, "data": {"message": f"Task {task_id} marked as {progress_data.status}", "status": progress.status}}

@app.get("/")
async def root():
    return {"message": "AI-Powered Upskilling Recommendation System"}

@app.get("/health")
async def health_check():
    is_demo = not ai_service.is_configured
    return {
        "status": "healthy",
        "environment": settings.ENVIRONMENT,
        "ai_provider": settings.AI_PROVIDER,
        "ai_status": "demo_mode" if is_demo else "configured",
    }

# Demo endpoint for when no API key is configured
@app.get("/api/demo-mode")
async def demo_mode():
    """Check if running in demo mode."""
    is_demo = not ai_service.is_configured
    return {
        "demo_mode": is_demo,
        "ai_provider": settings.AI_PROVIDER,
        "ai_model": settings.AI_MODEL or ("gemini-3-flash-preview" if settings.AI_PROVIDER.lower() == "gemini" else "default"),
        "message": (
            "Running in demo mode - AI provider not configured"
            if is_demo
            else f"AI provider '{settings.AI_PROVIDER}' configured"
        ),
    }

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)