from fastapi import FastAPI, HTTPException, Depends, status, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
import os

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
allowed_origins_str = os.environ.get("CORS_ORIGINS", "")
if allowed_origins_str:
    allow_origins = [origin.strip() for origin in allowed_origins_str.split(",") if origin.strip()]
else:
    # Default to localhost for development
    allow_origins = ["http://localhost:3000", "http://127.0.0.1:3000"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
    """Generate a personalized learning roadmap."""
    try:
        roadmap = await ai_service.generate_learning_roadmap(
            student_skills=request.student_skills,
            career_requirements=request.career_requirements,
            interests=request.interests,
            academic_background=request.academic_background,
            learning_goals=request.learning_goals,
        )
        return {"success": True, "data": roadmap}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate learning roadmap: {str(e)}",
        )

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

    # Find user by username
    user = db.query(User).filter(User.username == form_data.username).first()

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
    from app.database.models import StudentProfile

    profile = db.query(StudentProfile).filter(StudentProfile.user_id == current_user.id).first()

    if not profile:
        # Return default profile if none exists
        return {"success": True, "data": {"name": current_user.username, "email": current_user.email, "skills": []}}

    return {"success": True, "data": {
        "id": profile.id,
        "name": profile.name,
        "institution": profile.institution,
        "degree": profile.degree,
        "academic_year": profile.academic_year,
        "interests": profile.interests,
        "learning_goals": profile.learning_goals,
        "skills": [skill.skill_name for skill in profile.skills]
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
    from app.database.models import TaskProgress, RoadmapTask, LearningRoadmap

    # Get all tasks for this user
    tasks = db.query(TaskProgress).filter(TaskProgress.user_id == current_user.id).all()
    total_tasks = db.query(RoadmapTask).join(LearningRoadmap).filter(
        LearningRoadmap.user_id == current_user.id
    ).count()

    completed_tasks = sum(1 for t in tasks if t.status == "completed")

    percentage = int(completed_tasks / total_tasks * 100) if total_tasks > 0 else 0

    return {"success": True, "data": {
        "completed": completed_tasks,
        "total": total_tasks,
        "percentage": percentage,
        "task_details": [
            {"task_id": t.task_id, "status": t.status}
            for t in tasks
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
    from app.database.models import TaskProgress

    progress = db.query(TaskProgress).filter(
        TaskProgress.user_id == current_user.id,
        TaskProgress.task_id == task_id
    ).first()

    if not progress:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task {task_id} not found",
        )

    progress.status = progress_data.status
    db.commit()

    return {"success": True, "data": {"message": f"Task {task_id} marked as {progress_data.status}"}}

@app.get("/")
async def root():
    return {"message": "AI-Powered Upskilling Recommendation System"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "environment": "development", "ai_provider": "gemini", "ai_status": "demo_mode"}

# Demo endpoint for when no API key is configured
@app.get("/api/demo-mode")
async def demo_mode():
    """Check if running in demo mode."""
    from app.services.ai.service import AIService
    ai_service_demo = AIService()
    return {
        "demo_mode": ai_service_demo.provider is None,
        "message": "Running in demo mode - AI provider not configured" if ai_service_demo.provider is None else "AI provider configured"
    }

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)