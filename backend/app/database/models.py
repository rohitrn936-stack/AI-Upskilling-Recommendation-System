from datetime import datetime
from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    Text,
    ForeignKey,
    JSON,
    Index,
)
from sqlalchemy.orm import relationship

from app.database.connection import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    profile = relationship("StudentProfile", uselist=False, back_populates="user")
    skills = relationship("StudentSkill", back_populates="user")
    roadmaps = relationship("LearningRoadmap", back_populates="student")
    progress = relationship("TaskProgress", back_populates="user")


class StudentProfile(Base):
    __tablename__ = "student_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    name = Column(String, nullable=True)
    institution = Column(String, nullable=True)
    degree = Column(String, nullable=True)
    academic_year = Column(String, nullable=True)
    interests = Column(Text, nullable=True)
    learning_goals = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="profile")
    skills = relationship("StudentSkill", back_populates="profile", cascade="all, delete-orphan")


class StudentSkill(Base):
    __tablename__ = "student_skills"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    profile_id = Column(Integer, ForeignKey("student_profiles.id", ondelete="CASCADE"), nullable=True)
    skill_name = Column(String, nullable=False)
    proficiency_level = Column(String, nullable=True)  # beginner, intermediate, advanced, expert
    category = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="skills")
    profile = relationship("StudentProfile", back_populates="skills")


class Career(Base):
    __tablename__ = "careers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True, nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String, nullable=True)
    average_salary = Column(String, nullable=True)
    growth_outlook = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    required_skills = relationship("CareerRequiredSkill", back_populates="cascade_delete", cascade="all, delete-orphan")


class CareerRequiredSkill(Base):
    __tablename__ = "career_required_skills"

    id = Column(Integer, primary_key=True, index=True)
    career_id = Column(Integer, ForeignKey("careers.id", ondelete="CASCADE"), nullable=False)
    skill_name = Column(String, nullable=False)
    proficiency_required = Column(String, nullable=True)  # beginner, intermediate, advanced, expert
    importance_weight = Column(Integer, default=1)  # 1-5 scale
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    career = relationship("Career", back_populates="required_skills")


class CareerRecommendation(Base):
    __tablename__ = "career_recommendations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    career_id = Column(Integer, ForeignKey("careers.id", ondelete="SET NULL"), nullable=True)
    match_score = Column(Integer, nullable=True)  # 0-100
    reason = Column(Text, nullable=True)
    matching_skills = Column(JSON, nullable=True, default=list)
    missing_skills = Column(JSON, nullable=True, default=list)
    ai_provider = Column(String, nullable=True, default="gemini")
    ai_model = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="recommendations")
    career = relationship("Career", back_populates="recommendations")


class SkillGapAnalysis(Base):
    __tablename__ = "skill_gap_analyses"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    career_id = Column(Integer, ForeignKey("careers.id", ondelete="SET NULL"), nullable=True)
    match_percentage = Column(Integer, nullable=True)  # 0-100
    existing_skills = Column(JSON, nullable=True, default=list)
    required_skills = Column(JSON, nullable=True, default=list)
    missing_skills = Column(JSON, nullable=True, default=list)
    identified_skills = Column(JSON, nullable=True, default=list)
    ai_provider = Column(String, nullable=True, default="gemini")
    ai_model = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class LearningRoadmap(Base):
    __tablename__ = "learning_roadmaps"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    career_id = Column(Integer, ForeignKey("careers.id", ondelete="SET NULL"), nullable=True)
    title = Column(String, nullable=True)
    description = Column(Text, nullable=True)
    ai_provider = Column(String, nullable=True, default="gemini")
    ai_model = Column(String, nullable=True)
    version = Column(String, nullable=True, default="1.0")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    student = relationship("User", back_populates="roadmaps")
    career = relationship("Career", back_populates="roadmaps")
    phases = relationship("RoadmapPhase", back_populates="roadmap", cascade="all, delete-orphan")


class RoadmapVersion(Base):
    __tablename__ = "roadmap_versions"

    id = Column(Integer, primary_key=True, index=True)
    roadmap_id = Column(Integer, ForeignKey("learning_roadmaps.id", ondelete="CASCADE"), nullable=False)
    version_number = Column(String, nullable=False)
    title = Column(String, nullable=True)
    description = Column(Text, nullable=True)
    json_data = Column(JSON, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class RoadmapPhase(Base):
    __tablename__ = "roadmap_phases"

    id = Column(Integer, primary_key=True, index=True)
    roadmap_id = Column(Integer, ForeignKey("learning_roadmaps.id", ondelete="CASCADE"), nullable=False)
    phase_name = Column(String, nullable=False)
    phase_order = Column(Integer, nullable=False)
    description = Column(Text, nullable=True)
    estimated_duration = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    roadmap = relationship("LearningRoadmap", back_populates="phases")
    tasks = relationship("RoadmapTask", back_populates="phase", cascade="all, delete-orphan")


class RoadmapTask(Base):
    __tablename__ = "roadmap_tasks"

    id = Column(Integer, primary_key=True, index=True)
    phase_id = Column(Integer, ForeignKey("roadmap_phases.id", ondelete="CASCADE"), nullable=False)
    task_name = Column(String, nullable=False)
    task_description = Column(Text, nullable=True)
    skill_focus = Column(String, nullable=True)
    estimated_duration = Column(String, nullable=True)
    order_index = Column(Integer, nullable=False)
    completion_criteria = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    phase = relationship("RoadmapPhase", back_populates="tasks")


class LearningResource(Base):
    __tablename__ = "learning_resources"

    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("roadmap_tasks.id", ondelete="SET NULL"), nullable=True)
    resource_name = Column(String, nullable=False)
    platform = Column(String, nullable=True)  # e.g., Coursera, Udemy, YouTube
    description = Column(Text, nullable=True)
    resource_type = Column(String, nullable=True)  # article, video, course, book, tutorial
    url = Column(String, nullable=True)
    estimated_learning_duration = Column(String, nullable=True)
    is_verified = Column(Boolean, default=False)  # independently verified vs AI-suggested
    ai_provider = Column(String, nullable=True, default="gemini")
    created_at = Column(DateTime, default=datetime.utcnow)


class TaskProgress(Base):
    __tablename__ = "task_progress"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    task_id = Column(Integer, ForeignKey("roadmap_tasks.id", ondelete="CASCADE"), nullable=False)
    status = Column(String, nullable=False)  # completed, in_progress, not_started
    completed_at = Column(DateTime, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="progress")
    task = relationship("RoadmapTask")