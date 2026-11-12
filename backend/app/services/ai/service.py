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
            "provider": settings.AI_PROVIDER,
            "model": settings.AI_MODEL,
            "api_key": settings.AI_API_KEY,
            "base_url": settings.AI_BASE_URL,
            "temperature": settings.AI_TEMPERATURE,
            "timeout": settings.AI_TIMEOUT,
            "max_retries": settings.AI_MAX_RETRIES,
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
    
    @property
    def is_configured(self) -> bool:
        """Return True only when the configured AI provider has usable credentials."""
        self._initialize_provider()
        if not self.provider:
            return False
        if self._provider_type == "gemini" and not settings.AI_API_KEY:
            return False
        if self._provider_type == "compatible" and (not settings.AI_BASE_URL or not settings.AI_MODEL):
            return False
        if self._provider_type == "ollama" and not settings.AI_MODEL:
            return False
        return True

    async def generate(self, prompt: str, response_model: Optional[type] = None) -> Any:
        """Generate a response using the configured AI provider.
        
        Args:
            prompt: The prompt to send to the AI
            response_model: Optional Pydantic model to validate the response against
            
        Returns:
            AI response, either as a string or validated model instance
        """
        if not self.is_configured:
            # Return a structured demo response when no AI key/provider is configured
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
                "roadmap": {
                    "title": "Personalized Learning Roadmap",
                    "phases": [
                        {
                            "phase_name": "Phase 1: Fundamentals",
                            "phase_order": 1,
                            "description": "Learn programming and core computer science fundamentals",
                            "estimated_duration": "4 weeks",
                            "tasks": [
                                {
                                    "task_name": "Core Syntax & Data Structures",
                                    "description": "Practice arrays, hash maps, trees, and problem solving",
                                    "skill_focus": "Data Structures",
                                    "estimated_duration": "2 weeks",
                                    "completion_criteria": "Solve 20 core coding exercises",
                                },
                                {
                                    "task_name": "Version Control with Git",
                                    "description": "Master branching, merging, and collaborative workflows",
                                    "skill_focus": "Git",
                                    "estimated_duration": "2 weeks",
                                    "completion_criteria": "Push a structured project repository",
                                },
                            ],
                        }
                    ],
                },
                "message": "Demo mode: AI provider not configured. Showing sample roadmap.",
            }
        elif "resource" in prompt_lower:
            return {
                "demo_mode": True,
                "resources": [
                    {
                        "resource_name": "freeCodeCamp Full Curriculum",
                        "platform": "freeCodeCamp",
                        "description": "Interactive tutorials and hands-on projects",
                        "resource_type": "course",
                        "url": "https://www.freecodecamp.org/learn",
                        "estimated_learning_duration": "6 weeks",
                    },
                    {
                        "resource_name": "Official Python Tutorial",
                        "platform": "python.org",
                        "description": "Comprehensive core language reference and examples",
                        "resource_type": "article",
                        "url": "https://docs.python.org/3/tutorial/",
                        "estimated_learning_duration": "10 hours",
                    },
                ],
                "message": "Demo mode: AI provider not configured. Showing sample resources.",
            }
        elif "skill suggestion" in prompt_lower or "suggest" in prompt_lower:
            return {
                "demo_mode": True,
                "suggestions": [
                    {
                        "skill": "React",
                        "reason": "High demand in web development",
                        "priority": "high",
                        "explanation": "Expands your programming stack into modern frontend UIs",
                    }
                ],
                "message": "Demo mode: AI provider not configured. Showing sample skill suggestions.",
            }
        else:
            return {
                "demo_mode": True,
                "message": "Demo mode: AI provider not configured. Showing default response.",
            }

    @staticmethod
    def _parse_json_response(response: Any) -> Optional[Dict[str, Any]]:
        """Parse JSON string (including markdown-fenced JSON) into a dict."""
        if isinstance(response, dict):
            return response
        if not isinstance(response, str):
            return None
        text = response.strip()
        if text.startswith("```"):
            lines = text.splitlines()
            if lines and lines[0].startswith("```"):
                lines = lines[1:]
            if lines and lines[-1].strip().startswith("```"):
                lines = lines[:-1]
            text = "\n".join(lines).strip()
        try:
            parsed = json.loads(text)
            return parsed if isinstance(parsed, dict) else None
        except json.JSONDecodeError:
            # Extract embedded JSON object if surrounded by explanatory text or fences
            start = text.find("{")
            end = text.rfind("}")
            if start != -1 and end != -1 and end > start:
                try:
                    parsed = json.loads(text[start : end + 1])
                    return parsed if isinstance(parsed, dict) else None
                except json.JSONDecodeError:
                    return None
            return None

    @staticmethod
    def _coerce_text(value: Any) -> str:
        """Convert LLM fields cleanly into a readable string."""
        if value is None:
            return ""
        if isinstance(value, str):
            return value.strip()
        if isinstance(value, list):
            parts = [str(v).strip() for v in value if str(v).strip()]
            return "; ".join(parts)
        if isinstance(value, dict):
            for key in ("summary", "overview", "text", "interpretation"):
                if key in value and isinstance(value[key], str):
                    return value[key].strip()
            parts = [f"{k}: {v}" for k, v in value.items()]
            return " | ".join(parts)
        return str(value).strip()

    def _build_dynamic_demo_careers(
        self,
        skills: List[str],
        interests: str = "",
    ) -> Dict[str, Any]:
        """Compute skill-aware career recommendations when running in demo mode."""
        student_norm = {s.strip().lower(): s.strip() for s in skills if s.strip()}
        interest_lower = interests.lower()

        catalog = [
            {
                "career": "Software Engineer",
                "description": "Build and maintain scalable software applications, APIs, and distributed systems.",
                "required": ["Python", "JavaScript", "Data Structures", "SQL", "Git", "System Design", "DevOps"],
                "keywords": ["software", "web", "backend", "frontend", "app", "system", "code"],
            },
            {
                "career": "Data Scientist",
                "description": "Analyze complex datasets, build predictive statistical models, and communicate insights.",
                "required": ["Python", "SQL", "Statistics", "Data Analysis", "Machine Learning", "Data Visualization"],
                "keywords": ["data", "analytics", "statistics", "science", "bi"],
            },
            {
                "career": "Machine Learning Engineer",
                "description": "Design, train, optimize, and deploy production ML and deep learning pipelines.",
                "required": ["Python", "Machine Learning", "Deep Learning", "PyTorch", "TensorFlow", "Data Structures", "Docker"],
                "keywords": ["ai", "ml", "machine learning", "deep learning", "llm", "neural"],
            },
            {
                "career": "Full-Stack Web Developer",
                "description": "Create responsive frontend applications and robust REST/GraphQL backend services.",
                "required": ["JavaScript", "TypeScript", "React", "HTML/CSS", "Python", "SQL", "Git"],
                "keywords": ["web", "frontend", "backend", "react", "flutter", "ui"],
            },
        ]

        recommendations = []
        for entry in catalog:
            matching = []
            missing = []
            for req in entry["required"]:
                if req.lower() in student_norm:
                    matching.append(req)
                else:
                    missing.append(req)

            base_score = int(len(matching) / len(entry["required"]) * 80) + 15
            if any(kw in interest_lower for kw in entry["keywords"]):
                base_score = min(98, base_score + 10)
            match_score = max(35, min(98, base_score))

            if matching:
                reason = f"Matches your existing skills ({', '.join(matching)}) and fits this career track."
            else:
                reason = "Strong growth path; starting with foundational skills will build momentum quickly."

            recommendations.append({
                "career": entry["career"],
                "description": entry["description"],
                "match_score": match_score,
                "reason": reason,
                "matching_skills": matching,
                "missing_skills": missing,
                "required_skills": entry["required"],
            })

        recommendations.sort(key=lambda r: r["match_score"], reverse=True)
        return {
            "demo_mode": True,
            "recommendations": recommendations,
            "message": "Demo mode: Showing skill-matched career recommendations.",
        }

    def _build_dynamic_demo_suggestions(
        self,
        existing_skills: List[str],
        target_career: str,
        missing_skills: List[str],
    ) -> Dict[str, Any]:
        """Build personalized skill suggestions from missing skills in demo mode."""
        candidates = [s for s in missing_skills if s.strip()]
        if not candidates:
            candidates = ["System Design", "Machine Learning", "Docker", "Testing & CI/CD"]

        existing_str = ", ".join(existing_skills) if existing_skills else "your current foundation"
        career_label = target_career or "your target career"

        suggestions = []
        for idx, skill in enumerate(candidates[:5]):
            priority = "high" if idx < 2 else ("medium" if idx < 4 else "low")
            suggestions.append({
                "skill": skill,
                "reason": f"Core competency needed for {career_label}.",
                "priority": priority,
                "explanation": f"Builds on {existing_str} and closes a key gap for {career_label}.",
            })

        return {
            "demo_mode": True,
            "suggestions": suggestions,
            "message": "Demo mode: Showing suggestions based on your skill gaps.",
        }

    def _build_dynamic_demo_roadmap(
        self,
        student_skills: List[Dict[str, str]],
        career_requirements: List[Dict[str, str]],
    ) -> Dict[str, Any]:
        """Build a multi-phase learning roadmap tailored to missing skills in demo mode."""
        have = {s.get("skill_name", "").strip().lower() for s in student_skills if s.get("skill_name")}
        req_names = [r.get("skill_name", "").strip() for r in career_requirements if r.get("skill_name")]
        missing = [r for r in req_names if r.lower() not in have]

        focus_skills = missing if missing else (req_names[:4] if req_names else ["Python", "Data Structures", "System Design", "Capstone Project"])

        phases = []
        chunk_size = max(1, (len(focus_skills) + 2) // 3)
        phase_titles = [
            ("Phase 1: Core Foundations", "3 weeks", "Build solid fundamentals in your highest-priority gap skills."),
            ("Phase 2: Applied Tools & Frameworks", "4 weeks", "Apply intermediate concepts through guided exercises."),
            ("Phase 3: Integration & Portfolio Project", "4 weeks", "Combine skills into an end-to-end portfolio project."),
        ]

        for p_idx, (title, duration, desc) in enumerate(phase_titles):
            start = p_idx * chunk_size
            slice_skills = focus_skills[start : start + chunk_size]
            if not slice_skills and p_idx == 2:
                slice_skills = ["Capstone Portfolio Project"]
            if not slice_skills:
                continue

            tasks = []
            for skill in slice_skills:
                tasks.append({
                    "task_name": f"Learn & Practice {skill}",
                    "description": f"Study core concepts of {skill} and build a mini-project or coding exercise.",
                    "skill_focus": skill,
                    "estimated_duration": "1-2 weeks",
                    "completion_criteria": f"Complete a hands-on exercise demonstrating {skill}.",
                })

            phases.append({
                "phase_name": title,
                "phase_order": len(phases) + 1,
                "description": desc,
                "estimated_duration": duration,
                "tasks": tasks,
            })

        return {
            "demo_mode": True,
            "roadmap": {
                "title": "Personalized Upskilling Roadmap",
                "phases": phases,
            },
            "message": "Demo mode: Generated roadmap from your missing skills.",
        }

    def _build_dynamic_demo_resources(
        self,
        task_description: str,
        skill_focus: str,
        resource_type: str = "mixed",
    ) -> Dict[str, Any]:
        """Return verified educational resources matched to skill focus in demo mode."""
        topic = (skill_focus or task_description or "Programming").strip()
        topic_lower = topic.lower()

        resources = []
        if "python" in topic_lower:
            resources.append({
                "resource_name": "Official Python Tutorial",
                "platform": "python.org",
                "description": "Official language guide covering syntax, data structures, and standard library.",
                "resource_type": "Article",
                "url": "https://docs.python.org/3/tutorial/",
                "estimated_learning_duration": "10 hours",
            })
        if "machine learning" in topic_lower or "ml" in topic_lower or "scikit" in topic_lower:
            resources.append({
                "resource_name": "Machine Learning Crash Course",
                "platform": "Google Developers",
                "description": "Interactive guide to supervised learning, loss, and model evaluation.",
                "resource_type": "Course",
                "url": "https://developers.google.com/machine-learning/crash-course",
                "estimated_learning_duration": "15 hours",
            })
        if "deep learning" in topic_lower or "pytorch" in topic_lower or "tensorflow" in topic_lower:
            resources.append({
                "resource_name": "PyTorch Tutorials",
                "platform": "pytorch.org",
                "description": "Official hands-on tutorials for tensors, autograd, and neural networks.",
                "resource_type": "Tutorial",
                "url": "https://pytorch.org/tutorials/",
                "estimated_learning_duration": "3 weeks",
            })
        if "sql" in topic_lower or "database" in topic_lower:
            resources.append({
                "resource_name": "SQLBolt Interactive Lessons",
                "platform": "SQLBolt",
                "description": "Interactive SQL queries, joins, and aggregations in the browser.",
                "resource_type": "Tutorial",
                "url": "https://sqlbolt.com/",
                "estimated_learning_duration": "6 hours",
            })

        resources.extend([
            {
                "resource_name": f"{topic} Interactive Track",
                "platform": "freeCodeCamp",
                "description": f"Structured curriculum and project-based practice for {topic}.",
                "resource_type": "Course",
                "url": "https://www.freecodecamp.org/learn",
                "estimated_learning_duration": "4 weeks",
            },
            {
                "resource_name": f"{topic} Reference & Guides",
                "platform": "MDN / Official Docs",
                "description": f"Core concepts, guides, and best practices related to {topic}.",
                "resource_type": "Article",
                "url": "https://developer.mozilla.org/",
                "estimated_learning_duration": "5 hours",
            },
            {
                "resource_name": f"{topic} Video Lecture Series (MIT OCW / freeCodeCamp)",
                "platform": "MIT OpenCourseWare",
                "description": f"Recorded university lectures and guided walkthroughs covering {topic}.",
                "resource_type": "Video",
                "url": "https://ocw.mit.edu/",
                "estimated_learning_duration": "6 weeks",
            },
            {
                "resource_name": f"{topic} Companion Handbook & Open Textbooks",
                "platform": "Open Textbook Library / Git-SCM",
                "description": f"Comprehensive reading material and exercises to build depth in {topic}.",
                "resource_type": "Book",
                "url": "https://open.umn.edu/opentextbooks",
                "estimated_learning_duration": "4 weeks",
            },
        ])

        pref = (resource_type or "mixed").strip().lower()
        if pref and pref != "mixed":
            filtered = [r for r in resources if pref in r.get("resource_type", "").lower()]
            if filtered:
                resources = filtered

        return {
            "demo_mode": True,
            "resources": resources,
            "message": "Demo mode: Showing curated resources for your topic.",
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
            return self._build_dynamic_demo_careers(skills, interests)
        
        parsed = self._parse_json_response(response)
        if parsed and isinstance(parsed.get("recommendations") or parsed.get("careers"), list):
            parsed.setdefault("demo_mode", False)
            return parsed
        return self._build_dynamic_demo_careers(skills, interests)
    
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
            result["demo_mode"] = True
            if missing_skills:
                result["ai_interpretation"] = (
                    f"You match {match_percentage}% of the target skills. "
                    f"Prioritize learning {', '.join(missing_skills[:3])} next through hands-on projects."
                )
            else:
                result["ai_interpretation"] = (
                    "Great job! You already have all listed required skills for this role. "
                    "Focus on building portfolio projects and deepening proficiency."
                )
        else:
            parsed = self._parse_json_response(response)
            interp = ""
            if parsed:
                interp = self._coerce_text(parsed.get("interpretation"))
                if not interp and parsed.get("suggestions"):
                    interp = self._coerce_text(parsed.get("suggestions"))
            if not interp and isinstance(response, str):
                interp = response.strip()
            result["demo_mode"] = False if parsed else True
            result["ai_interpretation"] = interp or (
                f"You match {match_percentage}% of the target skills."
            )
        
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

Format the response as a JSON object with:
- "interpretation": a concise 2-3 sentence plain-text string summarizing career readiness and priorities
- "suggestions": array of prioritized missing skills with importance (critical, important, nice-to-have)
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
            return self._build_dynamic_demo_suggestions(existing_skills, target_career, missing_skills)
        
        parsed = self._parse_json_response(response)
        if parsed and isinstance(parsed.get("suggestions"), list) and parsed["suggestions"]:
            parsed.setdefault("demo_mode", False)
            return parsed
        return self._build_dynamic_demo_suggestions(existing_skills, target_career, missing_skills)
    
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
            return self._build_dynamic_demo_roadmap(student_skills, career_requirements)
        
        parsed = self._parse_json_response(response)
        phases = (
            parsed.get("roadmap", {}).get("phases")
            if isinstance(parsed, dict) and isinstance(parsed.get("roadmap"), dict)
            else (parsed.get("phases") if isinstance(parsed, dict) else None)
        )
        if parsed and isinstance(phases, list) and phases:
            parsed.setdefault("demo_mode", False)
            return parsed
        return self._build_dynamic_demo_roadmap(student_skills, career_requirements)
    
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

Create a structured learning roadmap with 3-5 phases. Each phase should have:
- phase_name: name of the phase
- phase_order: sequential order number
- description: what this phase covers
- estimated_duration: e.g., "4 weeks", "6 weeks"
- tasks: list of 2-3 tasks per phase, each with task_name, description, skill_focus, estimated_duration, and completion_criteria
- learning_objectives: what the student should achieve
- practical_exercises: hands-on activities or projects
- learning_resources: recommended resources (name, platform, type, url estimate)
- completion_criteria: how the student knows they've completed this phase

Format the response as a JSON object with a "roadmap" object containing "title" and "phases" array.
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
            return self._build_dynamic_demo_resources(task_description, skill_focus, resource_type)
        
        parsed = self._parse_json_response(response)
        if parsed and isinstance(parsed.get("resources"), list) and parsed["resources"]:
            parsed.setdefault("demo_mode", False)
            return parsed
        return self._build_dynamic_demo_resources(task_description, skill_focus, resource_type)
    
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