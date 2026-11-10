from abc import ABC, abstractmethod
from typing import Any, Dict, Optional, List
import json
import time
import asyncio


class AIProvider(ABC):
    """Base class for AI provider implementations."""

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.temperature = config.get("temperature", 0.3)
        self.timeout = config.get("timeout", 120)
        self.max_retries = config.get("max_retries", 3)

    @abstractmethod
    async def generate(self, prompt: str, response_model: Optional[type] = None) -> Any:
        """Generate a response from the AI provider."""
        pass

    @abstractmethod
    async def health_check(self) -> bool:
        """Check if the AI provider is healthy/available."""
        pass


class GeminiProvider(AIProvider):
    """Gemini AI provider integration."""

    def __init__(self, config: Dict[str, Any]):
        super().__init__(config)
        import google.generativeai as genai
        self.api_key = config.get("api_key", "")
        self.model_name = config.get("model", "gemini-pro")
        
        if self.api_key:
            genai.configure(api_key=self.api_key)
            self.model = genai.GenerativeModel(self.model_name)
        else:
            self.model = None
            self.genai = genai

    async def generate(self, prompt: str, response_model: Optional[type] = None) -> Any:
        """Generate text using Gemini API."""
        if not self.api_key or not self.model:
            raise ValueError("Gemini API key not configured")

        try:
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: self.model.generate_content(
                    prompt,
                    generation_config={
                        "temperature": self.temperature,
                        "max_output_tokens": 8192,
                    }
                )
            )
            
            if response.text:
                text = response.text.strip()
                # Try to parse as JSON if a model is provided
                if response_model:
                    try:
                        return response_model.model_validate_json(text)
                    except Exception:
                        pass
                return text
            else:
                raise ValueError("Empty response from Gemini")
                
        except Exception as e:
            raise AIProviderError(f"Gemini generation error: {str(e)}")

    async def health_check(self) -> bool:
        """Check if Gemini API is available."""
        if not self.api_key or not self.model:
            return False
        try:
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(
                None,
                lambda: self.model.generate_content(
                    "Health check",
                    generation_config={"temperature": 0, "max_output_tokens": 1}
                )
            )
            return True
        except Exception:
            return False


class OllamaProvider(AIProvider):
    """Ollama locally hosted LLM provider."""

    def __init__(self, config: Dict[str, Any]):
        super().__init__(config)
        self.base_url = config.get("base_url", "http://localhost:11434")
        self.model_name = config.get("model", "")
        
        if not self.model_name:
            raise ValueError("Ollama model name must be configured")

    async def generate(self, prompt: str, response_model: Optional[type] = None) -> Any:
        """Generate text using Ollama locally hosted LLM."""
        import aiohttp
        
        url = f"{self.base_url}/api/generate"
        payload = {
            "model": self.model_name,
            "prompt": prompt,
            "temperature": self.temperature,
            "stream": False,
        }
        
        for attempt in range(self.max_retries):
            try:
                timeout = aiohttp.ClientTimeout(total=self.timeout)
                async with aiohttp.ClientSession(timeout=timeout) as session:
                    async with session.post(url, json=payload) as response:
                        if response.status == 200:
                            result = await response.json()
                            text = result.get("response", "").strip()
                            
                            if response_model:
                                try:
                                    return response_model.model_validate_json(text)
                                except Exception:
                                    pass
                            return text
                        else:
                            raise AIProviderError(
                                f"Ollama error: status {response.status}"
                            )
            except asyncio.TimeoutError:
                if attempt < self.max_retries - 1:
                    await asyncio.sleep(1)
                    continue
                raise AIProviderError("Ollama request timed out")
            except aiohttp.ClientConnectorError as e:
                if attempt < self.max_retries - 1:
                    await asyncio.sleep(1)
                    continue
                raise AIProviderError(f"Ollama connection error: {str(e)}")
            except Exception as e:
                if attempt < self.max_retries - 1:
                    await asyncio.sleep(1)
                    continue
                raise AIProviderError(f"Ollama generation error: {str(e)}")
        
        raise AIProviderError("Ollama max retries exceeded")

    async def health_check(self) -> bool:
        """Check if Ollama server is available."""
        import aiohttp
        try:
            url = f"{self.base_url}/api/tags"
            async with aiohttp.ClientSession() as session:
                async with session.get(url, timeout=aiohttp.ClientTimeout(total=5)) as response:
                    return response.status == 200
        except Exception:
            return False


class CompatibleProvider(AIProvider):
    """Compatible API provider (OpenAI-style compatible endpoints)."""

    def __init__(self, config: Dict[str, Any]):
        super().__init__(config)
        self.base_url = config.get("base_url", "")
        self.api_key = config.get("api_key", "")
        self.model_name = config.get("model", "")
        
        if not self.model_name or not self.base_url:
            raise ValueError("Compatible provider must have base_url and model configured")

    async def generate(self, prompt: str, response_model: Optional[type] = None) -> Any:
        """Generate text using compatible API provider."""
        import aiohttp
        import json
        
        url = f"{self.base_url}/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": self.model_name,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": self.temperature,
            "max_tokens": 4096,
        }
        
        for attempt in range(self.max_retries):
            try:
                timeout = aiohttp.ClientTimeout(total=self.timeout)
                async with aiohttp.ClientSession(timeout=timeout) as session:
                    async with session.post(url, headers=headers, json=payload) as response:
                        if response.status == 200:
                            result = await response.json()
                            choice = result.get("choices", [{}])[0]
                            text = choice.get("message", {}).get("content", "").strip()
                            
                            if response_model:
                                try:
                                    return response_model.model_validate_json(text)
                                except Exception:
                                    pass
                            return text
                        else:
                            error_text = await response.text()
                            raise AIProviderError(
                                f"Compatible provider error: status {response.status}, "
                                f"details: {error_text}"
                            )
            except (asyncio.TimeoutError, aiohttp.ClientConnectorError) as e:
                if attempt < self.max_retries - 1:
                    await asyncio.sleep(1)
                    continue
                raise AIProviderError(f"Compatible provider connection error: {str(e)}")
            except Exception as e:
                if attempt < self.max_retries - 1:
                    await asyncio.sleep(1)
                    continue
                raise AIProviderError(f"Compatible provider generation error: {str(e)}")
        
        raise AIProviderError("Compatible provider max retries exceeded")

    async def health_check(self) -> bool:
        """Check if compatible provider is available."""
        import aiohttp
        try:
            url = f"{self.base_url}/v1/models"
            headers = {"Authorization": f"Bearer {self.api_key}"}
            async with aiohttp.ClientSession() as session:
                async with session.get(url, headers=headers, timeout=aiohttp.ClientTimeout(total=5)) as response:
                    return response.status == 200
        except Exception:
            return False


class AIProviderError(Exception):
    """Custom exception for AI provider errors."""
    pass


# Provider factory
class AIProviderFactory:
    """Factory class to create AI provider instances."""
    
    @staticmethod
    def create_provider(provider_type: str, config: Dict[str, Any]) -> AIProvider:
        """Create an AI provider instance based on the provider type."""
        providers = {
            "gemini": GeminiProvider,
            "ollama": OllamaProvider,
            "compatible": CompatibleProvider,
        }
        
        provider_class = providers.get(provider_type.lower())
        if not provider_class:
            raise AIProviderError(f"Unknown AI provider: {provider_type}")
        
        return provider_class(config)