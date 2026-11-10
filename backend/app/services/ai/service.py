from typing import Any, Optional, Dict, List
import json
import asyncio

from app.services.ai.providers.base import (
    AIProvider,
    AIProviderFactory,
    AIProviderError,
    GeminiProvider,
    OllamaProvider,
    CompatibleProvider,
)
from app.core.config import settings


class AIService:
    """Shared AI service that uses a configurable provider abstraction.
    
    This service handles all AI-powered functionality including:
    - Career recommendations
    - Skill-gap analysis
    - Personalized skill suggestions
    - Learning roadmap generation
    - Learning resource recommendations
    """
    
    def __init__(self):
        self.provider: Optional[AIProvider] = None
        self._initialized = False
        self._provider_type = settings.AI_PROVIDER.lower()
        self._config = self._build_config()
    
    def _build_config(self) -> Dict[str, Any]:
        """Build the AI provider configuration from environment settings."""
        return {
            "temperature": settings.AI_TEMPERATURE,
            "timeout": settings.AI_TIMEOUT,
            "max_retries": settings.AI_MAX_RETRIES,
            "api_key": settings.AI_API_KEY,
        }
    
    def _initialize_provider(self) -> None:
        """Initialize the AI provider based on the configured type."""
        if self._initialized:
            return
        
        try:
            self.provider = AIProviderFactory.create_provider(
                self._provider_type, self._config
            )
            self._initialized = True
        except AIProviderError as e:
            # If provider initialization fails (e.g., no API key for Gemini),
            # we still want the app to work in demo mode
            print(f"AI provider initialization warning: {e}")
            self.provider = None
    
    async def generate(self, prompt: str, response_model: Optional[type] = None) -> Any:
        """Generate a response using the configured AI provider.
        
        Args:
            prompt: The prompt to send to the AI
            response_model: Optional Pydantic model to validate the response against
            
        Returns:
            AI response, either as a string or validated model instance
        """
        if not self.provider:
            self._initialize_provider()
        
        if not self.provider:
            # Return a structured demo response when no AI is available
            return self._get_demo_response(prompt)
        
        try:
            return await self.provider.generate(prompt, response_model)
        except AIProviderError as e:
            # If AI fails, fall back to demo mode
            print(f"AI generation failed: {e}")
            return self._get_demo_response(prompt)
    
    def _get_demo_response(self, prompt: str) -> Dict[str, Any]:
        """Provide a structured demo response when AI is unavailable.
        
        This ensures the application remains functional without an API key,
        while clearly identifying that this is demo/mock data.
        """
        # Extract hints from the prompt to generate relevant demo data
        prompt_lower = prompt.lower()
        
        if "career" in prompt_lower and "recommend" in prompt_lower:
            return {
                "demo_mode": True,
                "recommendations": [
                    {
                        "career": "Software Engineer",
                        "match_score": 85,
                        "reason": "Student has strong foundation in programming and problem-solving",
                        "matching_skills": ["Python", "Java", "Data Structures"],
                        "missing_skills": ["System Design", "DevOps"]
                    }
                ],
                "message": "Demo mode: AI provider not configured. Showing sample recommendations."
            }
        elif "skill-gap" in prompt_lower or "gap" in prompt_lower:
            return {
                "demo_mode": True,
                "match_percentage": 72,
                "existing_skills": ["Python", "JavaScript", "SQL"],
                "required_skills": ["Python", "React", "Node.js"],
                "missing_skills": ["React", "Node.js"],
                "message": "Demo mode: AI provider not configured. Showing sample skill gap analysis."
            }
        elif "roadmap" in prompt_lower:
            return {
                "demo_mode": True,
                "phases": [
                    {
                        "phase_name": "Phase 1: Fundamentals",
                        "phase_order": 1,
                        "description": "Learn programming fundamentals",
                        "estimated_duration": "4 weeks"
                    }
                ],
                "message": "Demo mode: AI provider not configured. Showing sample roadmap."
            }
        elif "skill suggestion" in prompt_lower or "suggest" in prompt_lower:
            return {
                "demo_mode": True,
                "suggestions": [
                    {
                        "skill": "React",
                        "reason": "High demand in web development",
                        "priority": "high"
                    }
                ],
                "message": "Demo mode: AI provider not configured. Showing sample skill suggestions."
            }
        else:
            return {
                "demo_mode": True,
                "message": "Demo mode: AI provider not configured. Showing default response."
            }
    
    async def get_career_recommendations(
        self, 
        skills: List[str], 
        proficiency_levels: Dict[str, str],
        interests: str = "",
        academic_background: str = ""
    ) -> Dict[str, Any]:
        """Get career recommendations based on student skills.
        
        Args:
            skills: List of student skills
            proficiency_levels: Dict mapping skill to proficiency level
            interests: Student's interests
            academic_background: Student's academic background
            
        Returns:
            Career recommendations structured as JSON
        """
        prompt = self._build_career_recommendation_prompt(
            skills, proficiency_levels, interests, academic_background
        )
        
        response = await self.generate(prompt)
        
        # Ensure we have a valid structure
        if isinstance(response, dict) and response.get("demo_mode"):
            return response
        
        # Normalize the response
        if isinstance(response, str):
            try:
                response = json.loads(response)
            except json.JSONDecodeError:
                return self._get_demo_response(prompt)
        
        return response or self._get_demo_response(prompt)
    
    def _build_career_recommendation_prompt(
        self, 
        skills: List[str], 
        proficiency_levels: Dict[str, str],
        interests: str,
        academic_background: str
    ) -> str:
        """Build the prompt for career recommendations."""
        return """You are an AI career counselor. Based on the student's profile, recommend suitable career paths.

Student's skills: {skills}
Proficiency levels: {proficiency_levels}
Interests: {interests}
Academic background: {academic_background}

Provide 3-5 career recommendations with:
- career: career name
- match_score: percentage match (0-100)
- reason: brief explanation of why this career fits
- matching_skills: skills the student already has that are relevant
- missing_skills: key skills the student needs to develop

Format the response as a JSON object with a "recommendations" array.
""".format(
            skills=', '.join(skills),
            proficiency_levels=proficiency_levels,
            interests=interests,
            academic_background=academic_background
        )
    
    async def analyze_skill_gap(
        self,
        student_skills: List[Dict[str, str]],
        required_skills: List[Dict[str, str]]
    ) -> Dict[str, Any]:
        """Analyze skill gaps between student skills and required skills.
        
        Uses deterministic backend logic for the match percentage,
        and AI for contextual interpretation.
        
        Args:
            student_skills: List of {skill_name, proficiency} dicts
            required_skills: List of {skill_name, proficiency_required} dicts
            
        Returns:
            Skill gap analysis with match percentage and AI interpretation
        """
        # Deterministic calculation of match percentage
        student_skill_set = {s.get("skill_name", "").lower().strip() for s in student_skills}
        required_skill_set = {s.get("skill_name", "").lower().strip() for s in required_skills}
        
        if not required_skill_set:
            match_percentage = 100
        else:
            matching = student_skill_set & required_skill_set
            match_percentage = int(len(matching) / len(required_skill_set) * 100) if required_skill_set else 0
        
        missing_skills = list(required_skill_set - student_skill_set)
        existing_skills = list(student_skill_set & required_skill_set)
        
        prompt = self._build_skill_gap_prompt(
            student_skills, required_skills, match_percentage, missing_skills, existing_skills
        )
        
        response = await self.generate(prompt)
        
        # Combine deterministic calculation with AI interpretation
        result = {
            "match_percentage": match_percentage,
            "existing_skills": existing_skills,
            "missing_skills": missing_skills,
            "required_skills": [s.get("skill_name", "") for s in required_skills],
        }
        
        if isinstance(response, dict) and response.get("demo_mode"):
            # Add AI interpretation even in demo mode
            result["ai_interpretation"] = response.get("message", "")
        elif isinstance(response, dict):
            # Add AI interpretation from actual AI
            result["ai_interpretation"] = response.get("interpretation", "")
        else:
            result["ai_interpretation"] = self._extract_ai_interpretation(response)
        
        return result
    
    def _build_skill_gap_prompt(
        self,
        student_skills: List[Dict[str, str]],
        required_skills: List[Dict[str, str]],
        match_percentage: int,
        missing_skills: List[str],
        existing_skills: List[str]
    ) -> str:
        """Build the prompt for skill gap analysis."""
        missing_str = ', '.join(missing_skills) if missing_skills else 'None'
        existing_str = ', '.join(existing_skills) if existing_skills else 'None'
        return f"""You are an AI skill analyst. Analyze the skill gap between a student's existing skills and the requirements for a career.

Student's skills: {json.dumps(student_skills, ensure_ascii=False)}
Required skills: {json.dumps(required_skills, ensure_ascii=False)}
Skill match percentage: {match_percentage}%
Missing skills: {missing_str}
Existing/ matching skills: {existing_str}

Provide:
- A contextual interpretation of what this skill gap means for the student's career prospects
- Personalized suggestions for which missing skills to prioritize first
- The importance of each missing skill (critical, important, nice-to-have)

Format the response as a JSON object with "interpretation" and "suggestions" fields.
"""
    
    def _extract_ai_interpretation(self, response: str) -> str:
        """Extract interpretation from AI response string."""
        try:
            data = json.loads(response)
            return data.get("interpretation", "AI analysis pending.")
        except (json.JSONDecodeError, TypeError):
            return "AI analysis pending."
    
    async def generate_personalized_skills(
        self,
        existing_skills: List[str],
        target_career: str,
        missing_skills: List[str],
        learning_goals: str = ""
    ) -> Dict[str, Any]:
        """Generate personalized skill suggestions based on student profile.
        
        Args:
            existing_skills: List of student's current skills
            target_career: The target career path
            missing_skills: Skills identified as missing
            learning_goals: Student's learning goals
            
        Returns:
            Personalized skill suggestions with explanations
        """
        prompt = self._build_personalized_skills_prompt(
            existing_skills, target_career, missing_skills, learning_goals
        )
        
        response = await self.generate(prompt)
        
        if isinstance(response, dict) and response.get("demo_mode"):
            return response
        
        if isinstance(response, str):
            try:
                response = json.loads(response)
            except json.JSONDecodeError:
                return self._get_demo_response(prompt)
        
        return response or self._get_demo_response(prompt)
    
    def _build_personalized_skills_prompt(
        self,
        existing_skills: List[str],
        target_career: str,
        missing_skills: List[str],
        learning_goals: str
    ) -> str:
        """Build the prompt for personalized skill suggestions."""
        missing_str = ', '.join(missing_skills) if missing_skills else 'None'
        return f"""You are an AI learning coach. Based on the student's profile, suggest relevant skills to learn.

Existing skills: {', '.join(existing_skills)}
Target career: {target_career}
Currently missing skills: {missing_str}
Learning goals: {learning_goals}

Provide 3-5 skill suggestions with:
- skill: the skill name
- reason: why this skill is relevant given their profile
- priority: high/medium/low priority
- explanation: how this skill connects to their existing skills and career goals

Format the response as a JSON object with a "suggestions" array.
"""
    
    async def generate_learning_roadmap(
        self,
        student_skills: List[Dict[str, str]],
        career_requirements: List[Dict[str, str]],
        interests: str = "",
        academic_background: str = "",
        learning_goals: str = ""
    ) -> Dict[str, Any]:
        """Generate a personalized learning roadmap.
        
        Args:
            student_skills: List of {skill_name, proficiency} dicts
            career_requirements: List of {skill_name, proficiency_required} dicts
            interests: Student's interests
            academic_background: Student's academic background
            learning_goals: Student's learning goals
            
        Returns:
            Learning roadmap with phases, tasks, and resources
        """
        prompt = self._build_roadmap_prompt(
            student_skills, career_requirements, interests, academic_background, learning_goals
        )
        
        response = await self.generate(prompt)
        
        if isinstance(response, dict) and response.get("demo_mode"):
            return response
        
        if isinstance(response, str):
            try:
                response = json.loads(response)
            except json.JSONDecodeError:
                return self._get_demo_response(prompt)
        
        return response or self._get_demo_response(prompt)
    
    def _build_roadmap_prompt(
        self,
        student_skills: List[Dict[str, str]],
        career_requirements: List[Dict[str, str]],
        interests: str,
        academic_background: str,
        learning_goals: str
    ) -> str:
        """Build the prompt for learning roadmap generation."""
        return f"""You are an AI education architect. Create a personalized learning roadmap for a student.

Student's current skills: {json.dumps(student_skills, ensure_ascii=False)}
Skills required for target career: {json.dumps(career_requirements, ensure_ascii=False)}
Student's interests: {interests}
Academic background: {academic_background}
Learning goals: {learning_goals}

Create a structured learning roadmap with 4-6 phases. Each phase should have:
- phase_name: name of the phase
- phase_order: sequential order number
- description: what this phase covers
- estimated_duration: e.g., "4 weeks", "6 weeks"
- tasks: list of tasks with task_name, description, skill_focus, estimated_duration
- learning_objectives: what the student should achieve
- practical_exercises: hands-on activities or projects
- learning_resources: recommended resources (name, platform, type, url estimate)
- completion_criteria: how the student knows they've completed this phase

Format the response as a JSON object with a "roadmap" containing "phases" array.
Each phase should contain "tasks" array, "learning_objectives", "estimated_duration",
"practical_exercises", "learning_resources", and "completion_criteria".
"""
    
    async def recommend_learning_resources(
        self,
        task_description: str,
        skill_focus: str = "",
        resource_type: str = "mixed"
    ) -> Dict[str, Any]:
        """Recommend learning resources for a specific task or skill.
        
        Args:
            task_description: Description of the task or skill to learn
            skill_focus: The skill the resources focus on
            resource_type: Type of resources (video, article, course, book, mixed)
            
        Returns:
            Learning resources recommendations
        """
        prompt = self._build_resource_recommendation_prompt(
            task_description, skill_focus, resource_type
        )
        
        response = await self.generate(prompt)
        
        if isinstance(response, dict) and response.get("demo_mode"):
            return response
        
        if isinstance(response, str):
            try:
                response = json.loads(response)
            except json.JSONDecodeError:
                return self._get_demo_response(prompt)
        
        return response or self._get_demo_response(prompt)
    
    def _build_resource_recommendation_prompt(
        self,
        task_description: str,
        skill_focus: str,
        resource_type: str
    ) -> str:
        """Build the prompt for learning resource recommendations."""
        return f"""You are an AI learning resource recommender. Suggest useful resources for learning {skill_focus or 'this topic'}.

Task/skill description: {task_description}
Resource type preference: {resource_type} (video, article, course, book, or mixed)

Provide 3-5 resources with:
- resource_name: name of the resource
- platform: e.g., Coursera, Udemy, YouTube, edX, book title
- description: brief description of what's covered
- resource_type: video, article, course, book, tutorial
- url: verified educational resource URL (do not fabricate - use real known resources)
- estimated_learning_duration: e.g., "2 hours", "4 weeks", "10 hours"

Important: Only include URLs for real, verified educational resources. 
Do not fabricate or make up URLs. Clearly mark which resources are 
AI-suggested vs independently verified.

Format the response as a JSON object with a "resources" array.
"""