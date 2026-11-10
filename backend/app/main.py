from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy import text
import uvicorn

from app.database.connection import SessionLocal, engine
from app.database.models import Base
from app.core.config import settings
from app.services.ai.service import AIService

# Database tables will be created via migrations
# Base.metadata.create_all(bind=engine)  # Disabled - using migrations instead

# Initialize AI service
ai_service = AIService()

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Create FastAPI app
app = FastAPI(
    title="AI-Powered Upskilling Recommendation System",
    description="Intelligent application that helps students identify suitable career opportunities based on their existing skills",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


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
try:
    import jwt
    import datetime
    
    def create_access_token(data: dict, expires_delta: datetime.timedelta = None):
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.datetime.utcnow() + expires_delta
        else:
            expire = datetime.datetime.utcnow() + datetime.timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm="HS256")
        return encoded_jwt
    
    def decode_access_token(token: str):
        try:
            payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=["HS256"])
            return payload
        except jwt.ExpiredSignatureError:
            return None
        except jwt.JWTError:
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
    
except ImportError:
    # JWT not available, simplified auth
    def create_access_token(data: dict, expires_delta=None):
        return "demo-token"
    
    def decode_access_token(token: str):
        return None
    
    def get_current_user(db: Session, token: str):
        return None


@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "AI-Powered Upskilling Recommendation System API", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    ai_status = "available" if ai_service.provider else "demo_mode"
    return {
        "status": "healthy",
        "environment": settings.ENVIRONMENT,
        "ai_provider": settings.AI_PROVIDER,
        "ai_status": ai_status,
    }


# AI endpoints
@app.get("/api/ai/status")
async def ai_status():
    """Get AI service status."""
    return {
        "provider": settings.AI_PROVIDER,
        "model": settings.AI_MODEL,
        "available": ai_service.provider is not None,
        "demo_mode": ai_service.provider is None,
    }


@app.post("/api/ai/career-recommendations")
async def career_recommendations(
    skills: list,
    proficiency: dict = {},
    interests: str = "",
    academic_background: str = "",
    db: Session = Depends(get_db),
):
    """Get career recommendations based on student skills."""
    try:
        from sqlalchemy import select
        from app.database.models import User
        # Get current user from DB if authenticated
        user = None
        token = None  # Would be extracted from auth header in full implementation
        
        recommendations = await ai_service.get_career_recommendations(
            skills=skills,
            proficiency_levels=proficiency,
            interests=interests,
            academic_background=academic_background,
        )
        return {"success": True, "data": recommendations}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate career recommendations: {str(e)}",
        )


@app.post("/api/ai/skill-gap-analysis")
async def skill_gap_analysis(
    student_skills: list,
    required_skills: list,
    db: Session = Depends(get_db),
):
    """Analyze skill gaps between student skills and career requirements."""
    try:
        analysis = await ai_service.analyze_skill_gap(
            student_skills=[{"skill_name": s, "proficiency": p} for s, p in student_skills],
            required_skills=[{"skill_name": s, "proficiency_required": p} for s, p in required_skills],
        )
        return {"success": True, "data": analysis}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to analyze skill gap: {str(e)}",
        )


@app.post("/api/ai/personalized-skills")
async def personalized_skills(
    existing_skills: list,
    target_career: str,
    missing_skills: list = [],
    learning_goals: str = "",
    db: Session = Depends(get_db),
):
    """Get personalized skill suggestions."""
    try:
        suggestions = await ai_service.generate_personalized_skills(
            existing_skills=existing_skills,
            target_career=target_career,
            missing_skills=missing_skills,
            learning_goals=learning_goals,
        )
        return {"success": True, "data": suggestions}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate personalized skills: {str(e)}",
        )


@app.post("/api/ai/roadmap-generate")
async def generate_roadmap(
    student_skills: list,
    career_requirements: list,
    interests: str = "",
    academic_background: str = "",
    learning_goals: str = "",
    db: Session = Depends(get_db),
):
    """Generate a personalized learning roadmap."""
    try:
        roadmap = await ai_service.generate_learning_roadmap(
            student_skills=[{"skill_name": s, "proficiency": p} for s, p in student_skills],
            career_requirements=[{"skill_name": s, "proficiency_required": p} for s, p in career_requirements],
            interests=interests,
            academic_background=academic_background,
            learning_goals=learning_goals,
        )
        return {"success": True, "data": roadmap}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate learning roadmap: {str(e)}",
        )


@app.post("/api/ai/recommend-resources")
async def recommend_resources(
    task_description: str,
    skill_focus: str = "",
    resource_type: str = "mixed",
    db: Session = Depends(get_db),
):
    """Recommend learning resources for a task."""
    try:
        resources = await ai_service.recommend_learning_resources(
            task_description=task_description,
            skill_focus=skill_focus,
            resource_type=resource_type,
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
    email: str,
    username: str,
    password: str,
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

# Dependency to get current user
def get_current_user_dependency(db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)):
    user = get_current_user(db, token)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )
    return user


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
    profile_data: dict,
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
            name=profile_data.get("name", current_user.username),
            institution=profile_data.get("institution", ""),
            degree=profile_data.get("degree", ""),
            academic_year=profile_data.get("academic_year", ""),
            interests=profile_data.get("interests", ""),
            learning_goals=profile_data.get("learning_goals", ""),
        )
        db.add(profile)
    else:
        profile.name = profile_data.get("name", profile.name)
        profile.institution = profile_data.get("institution", profile.institution)
        profile.degree = profile_data.get("degree", profile.degree)
        profile.academic_year = profile_data.get("academic_year", profile.academic_year)
        profile.interests = profile_data.get("interests", profile.interests)
        profile.learning_goals = profile_data.get("learning_goals", profile.learning_goals)
    
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
    }}


# Skill management endpoints
@app.get("/api/skills")
async def list_skills(
    current_user = Depends(get_current_user_dependency),
    db: Session = Depends(get_db),
):
    """List student's skills."""
    from app.database.models import StudentSkill
    
    skills = db.query(StudentSkill).filter(StudentSkill.user_id == current_user.id).all()
    return {"success": True, "data": {
        "skills": [
            {
                "id": skill.id,
                "skill_name": skill.skill_name,
                "proficiency_level": skill.proficiency_level,
                "category": skill.category,
            } for skill in skills
        ]
    }}


@app.post("/api/skills")
async def add_skill(
    skill_name: str,
    proficiency: str = "beginner",
    category: str = "",
    current_user = Depends(get_current_user_dependency),
    db: Session = Depends(get_db),
):
    """Add a skill for the current user."""
    from app.database.models import StudentSkill
    
    new_skill = StudentSkill(
        user_id=current_user.id,
        skill_name=skill_name,
        proficiency_level=proficiency,
        category=category,
    )
    db.add(new_skill)
    db.commit()
    
    return {"success": True, "data": {"message": f"Skill '{skill_name}' added", "skill_id": new_skill.id}}


@app.put("/api/skills/{skill_id}")
async def update_skill(
    skill_id: int,
    proficiency: str = "",
    category: str = "",
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
    
    if proficiency:
        skill.proficiency_level = proficiency
    if category:
        skill.category = category
    
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
    return {"success": True, "data": {
        "careers": [
            {
                "id": c.id,
                "name": c.name,
                "description": c.description,
                "category": c.category,
                "average_salary": c.average_salary,
                "growth_outlook": c.growth_outlook,
            } for c in careers
        ]
    }}


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
            {
                "task_id": t.task_id,
                "status": t.status,
            } for t in tasks
        ]
    }}


@app.post("/api/progress/{task_id}")
async def update_progress(
    task_id: int,
    status: str,
    current_user = Depends(get_current_user_dependency),
    db: Session = Depends(get_db),
):
    """Update task progress."""
    from app.database.models import TaskProgress
    
    progress = db.query(TaskProgress).filter(
        TaskProgress.user_id == current_user.id,
        TaskProgress.task_id == task_id
    ).first()
    
    if not progress:
        progress = TaskProgress(
            user_id=current_user.id,
            task_id=task_id,
            status=status,
        )
        db.add(progress)
    else:
        progress.status = status
        progress.updated_at = datetime.utcnow() if hasattr(progress, 'updated_at') else None
    
    db.commit()
    
    return {"success": True, "data": {"message": f"Task {task_id} marked as {status}"}}


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