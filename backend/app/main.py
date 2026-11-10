from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
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


# Helper functions for authentication (simplified for now)
def get_current_user(db: Session, token: str):
    """Get the current user from the JWT token."""
    # In a full implementation, verify the JWT and return the user
    # For now, return None to indicate unauthenticated
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


# User authentication endpoints (placeholder)
@app.post("/api/auth/register")
async def register(
    email: str,
    username: str,
    password: str,
    db: Session = Depends(get_db),
):
    """User registration."""
    # Placeholder - will be fully implemented with hashing, etc.
    user = {"email": email, "username": username, "id": 1}
    return {"success": True, "data": user}


@app.post("/api/auth/login")
async def login(
    db: Session = Depends(get_db),
):
    """User login."""
    # Placeholder - will be fully implemented with JWT
    return {"success": True, "data": {"access_token": "demo-token", "token_type": "bearer"}}


# Profile endpoints
@app.get("/api/profile")
async def get_profile(db: Session = Depends(get_db)):
    """Get student profile."""
    user = get_current_user(db, "")
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )
    return {"success": True, "data": {"name": "Student", "email": "student@example.com"}}


@app.post("/api/profile")
async def update_profile(
    profile_data: dict,
    db: Session = Depends(get_db),
):
    """Update student profile."""
    user = get_current_user(db, "")
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )
    return {"success": True, "data": {"message": "Profile updated successfully"}}


# Skill management endpoints
@app.get("/api/skills")
async def list_skills(db: Session = Depends(get_db)):
    """List student's skills."""
    user = get_current_user(db, "")
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )
    return {"success": True, "data": {"skills": []}}


@app.post("/api/skills")
async def add_skill(
    skill_name: str,
    proficiency: str = "beginner",
    category: str = "",
    db: Session = Depends(get_db),
):
    """Add a skill."""
    user = get_current_user(db, "")
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )
    return {"success": True, "data": {"message": f"Skill '{skill_name}' added"}}


@app.put("/api/skills/{skill_id}")
async def update_skill(
    skill_id: int,
    proficiency: str = "",
    category: str = "",
    db: Session = Depends(get_db),
):
    """Update a skill."""
    user = get_current_user(db, "")
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )
    return {"success": True, "data": {"message": f"Skill {skill_id} updated"}}


@app.delete("/api/skills/{skill_id}")
async def delete_skill(
    skill_id: int,
    db: Session = Depends(get_db),
):
    """Delete a skill."""
    user = get_current_user(db, "")
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )
    return {"success": True, "data": {"message": f"Skill {skill_id} deleted"}}


# Career endpoints
@app.get("/api/careers")
async def list_careers(db: Session = Depends(get_db)):
    """List available careers."""
    # Placeholder career data
    careers = [
        {"id": 1, "name": "Software Engineer", "description": "Build and maintain software applications"},
        {"id": 2, "name": "Data Scientist", "description": "Analyze complex data to extract insights"},
        {"id": 3, "name": "Machine Learning Engineer", "description": "Develop ML models and systems"},
    ]
    return {"success": True, "data": {"careers": careers}}


@app.get("/api/careers/{career_id}")
async def get_career(
    career_id: int,
    db: Session = Depends(get_db),
):
    """Get career details."""
    careers = {
        1: {"id": 1, "name": "Software Engineer", "description": "Build and maintain software applications"},
        2: {"id": 2, "name": "Data Scientist", "description": "Analyze complex data to extract insights"},
        3: {"id": 3, "name": "Machine Learning Engineer", "description": "Develop ML models and systems"},
    }
    career = careers.get(career_id)
    if not career:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Career not found",
        )
    return {"success": True, "data": career}


# Roadmap progress endpoints
@app.get("/api/progress")
async def get_progress(db: Session = Depends(get_db)):
    """Get learning progress."""
    user = get_current_user(db, "")
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )
    return {"success": True, "data": {"completed": 0, "total": 0, "percentage": 0}}


@app.post("/api/progress/{task_id}")
async def update_progress(
    task_id: int,
    status: str,
    db: Session = Depends(get_db),
):
    """Update task progress."""
    user = get_current_user(db, "")
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )
    return {"success": True, "data": {"message": f"Task {task_id} marked as {status}"}}


if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)