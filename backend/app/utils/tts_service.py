"""
Speech Generator Module using Edge-TTS for Swasthya Healthcare
Provides TTS generation with Microsoft Edge's Text-to-Speech service (free, reliable, high quality)
Adapted from Ashlya Academy for medical consultations
"""
import os
import uuid
import logging
import asyncio
from datetime import datetime
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)

# Try to import edge-tts
try:
    import edge_tts
    EDGE_TTS_AVAILABLE = True
    logger.info("edge-tts package is available. TTS features enabled.")
except ImportError as e:
    EDGE_TTS_AVAILABLE = False
    logger.warning(f"edge-tts package not available: {e}. Install with: pip install edge-tts")

# Voice mapping - Edge TTS voices with language support for medical use
EDGE_TTS_VOICES = {
    # English voices - calm, professional for medical
    "en-US": {
        "nova": "en-US-JennyNeural",      # Female, friendly - good for medical
        "alloy": "en-US-AriaNeural",       # Female, professional
        "echo": "en-US-GuyNeural",         # Male, casual
        "fable": "en-GB-SoniaNeural",      # British female
        "onyx": "en-US-DavisNeural",       # Male, deep - calming for anxiety
        "shimmer": "en-US-SaraNeural",     # Female, warm - pediatric friendly
        "sage": "en-US-JennyNeural",       # Alias for nova
        "coral": "en-US-MichelleNeural",   # Female, expressive
        "ash": "en-US-TonyNeural",         # Male, clear
    },
    # Nepali - Important for Nepal healthcare
    "ne-NP": {
        "default": "ne-NP-SagarNeural",    # Male
        "female": "ne-NP-HemkalaNeural",   # Female
        "nova": "ne-NP-HemkalaNeural",
        "sage": "ne-NP-SagarNeural",
    },
    # Hindi - For North Indian patients
    "hi-IN": {
        "default": "hi-IN-SwaraNeural",    # Female
        "male": "hi-IN-MadhurNeural",      # Male
        "nova": "hi-IN-SwaraNeural",
        "sage": "hi-IN-MadhurNeural",
    },
    # Spanish
    "es-ES": {
        "default": "es-ES-ElviraNeural",
        "male": "es-ES-AlvaroNeural",
        "nova": "es-ES-ElviraNeural",
        "sage": "es-ES-AlvaroNeural",
    },
    # French
    "fr-FR": {
        "default": "fr-FR-DeniseNeural",
        "male": "fr-FR-HenriNeural",
        "nova": "fr-FR-DeniseNeural",
        "sage": "fr-FR-HenriNeural",
    },
    # German
    "de-DE": {
        "default": "de-DE-KatjaNeural",
        "male": "de-DE-ConradNeural",
        "nova": "de-DE-KatjaNeural",
        "sage": "de-DE-ConradNeural",
    },
}

# Default fallback voice
DEFAULT_VOICE = "en-US-JennyNeural"

# Audio output directory
AUDIO_OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "generated_audio")
os.makedirs(AUDIO_OUTPUT_DIR, exist_ok=True)

# Language names
LANGUAGE_NAMES = {
    'en-US': 'English',
    'hi-IN': 'Hindi', 
    'ne-NP': 'Nepali',
    'es-ES': 'Spanish',
    'fr-FR': 'French',
    'de-DE': 'German'
}


def get_edge_voice(voice_name: str, language_code: str = "en-US") -> str:
    """Get the Edge TTS voice name for the given voice and language"""
    voice_name = voice_name.lower() if voice_name else "nova"
    
    # Get language voices, fall back to en-US
    lang_voices = EDGE_TTS_VOICES.get(language_code, EDGE_TTS_VOICES.get("en-US", {}))
    
    # Try to find the voice, fall back to default
    if voice_name in lang_voices:
        return lang_voices[voice_name]
    elif "default" in lang_voices:
        return lang_voices["default"]
    else:
        return DEFAULT_VOICE


def get_optimal_voice(language_code: str) -> str:
    """Get optimal voice for a given language"""
    return "nova"  # Default to female voice for medical - more calming


def clean_text_for_tts(text: str) -> str:
    """Clean text for better TTS output"""
    import re
    
    # Remove markdown
    text = re.sub(r'\*\*([^*]+)\*\*', r'\1', text)
    text = re.sub(r'\*([^*]+)\*', r'\1', text)
    text = text.replace('```', '')
    text = text.replace('`', '')
    
    # Replace medical emojis with words
    emoji_replacements = {
        '⚠️': 'Warning.',
        '🏥': 'Hospital',
        '💊': 'Medicine',
        '🩺': 'Doctor',
        '❤️': 'Heart',
        '✅': 'Check',
        '❌': 'No',
        '🚨': 'Emergency!',
        '💉': 'Injection',
        '🩸': 'Blood',
    }
    for emoji, text_replacement in emoji_replacements.items():
        text = text.replace(emoji, text_replacement)
    
    # Clean whitespace
    text = re.sub(r'\s+', ' ', text).strip()
    
    return text


class SpeechGenerator:
    """Speech generator using Edge-TTS for medical consultations"""
    
    def __init__(self, audio_output_dir: str = None):
        """Initialize the speech generator"""
        self.audio_dir = audio_output_dir or AUDIO_OUTPUT_DIR
        os.makedirs(self.audio_dir, exist_ok=True)
        logger.info(f"SpeechGenerator initialized with output dir: {self.audio_dir}")
    
    async def generate_speech_async(
        self,
        text: str,
        voice: str = "nova",
        audio_format: str = "mp3",
        speed: float = 1.0,
        language_code: str = "en-US"
    ) -> Dict[str, Any]:
        """Generate speech from text using Edge-TTS"""
        
        if not EDGE_TTS_AVAILABLE:
            return {
                "status": "error",
                "message": "TTS not available. Install: pip install edge-tts"
            }
        
        if not text or not text.strip():
            return {
                "status": "error",
                "message": "No text provided"
            }
        
        try:
            # Clean text for medical TTS
            clean_text = clean_text_for_tts(text)
            
            # Get the Edge TTS voice
            edge_voice = get_edge_voice(voice, language_code)
            
            # Calculate rate adjustment
            speed = max(0.5, min(2.0, speed))
            rate_percent = int((speed - 1.0) * 100)
            rate_str = f"+{rate_percent}%" if rate_percent >= 0 else f"{rate_percent}%"
            
            logger.info(f"Generating speech: voice={edge_voice}, rate={rate_str}, chars={len(clean_text)}")
            
            # Generate unique filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            random_id = str(uuid.uuid4())[:8]
            filename = f"swasthya_tts_{language_code}_{timestamp}_{random_id}.{audio_format}"
            file_path = os.path.join(self.audio_dir, filename)
            
            # Create communicator and generate speech
            communicate = edge_tts.Communicate(clean_text, edge_voice, rate=rate_str)
            await communicate.save(file_path)
            
            # Verify file was created
            if not os.path.exists(file_path):
                raise Exception("Audio file was not created")
            
            file_size = os.path.getsize(file_path)
            
            if file_size == 0:
                os.remove(file_path)
                raise Exception("Generated audio file is empty")
            
            logger.info(f"Speech generated: {filename} ({file_size} bytes)")
            
            return {
                "status": "success",
                "message": "Speech generated",
                "filename": filename,
                "file_path": file_path,
                "file_size": file_size,
                "url": f"/api/ai-sathi/audio/{filename}",
                "voice": voice,
                "edge_voice": edge_voice,
                "format": audio_format,
                "text_length": len(text),
                "language_code": language_code
            }
            
        except Exception as e:
            logger.error(f"Error generating speech: {e}")
            return {
                "status": "error",
                "message": f"Failed to generate speech: {str(e)}"
            }
    
    def generate_speech(
        self,
        text: str,
        voice: str = "nova",
        audio_format: str = "mp3",
        speed: float = 1.0,
        language_code: str = "en-US"
    ) -> Dict[str, Any]:
        """Synchronous wrapper for speech generation"""
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            return loop.run_until_complete(
                self.generate_speech_async(
                    text=text,
                    voice=voice,
                    audio_format=audio_format,
                    speed=speed,
                    language_code=language_code
                )
            )
        finally:
            loop.close()
    
    def get_available_voices(self, language_code: str = "en-US") -> list:
        """Get list of available voices for a language"""
        lang_voices = EDGE_TTS_VOICES.get(language_code, EDGE_TTS_VOICES.get("en-US", {}))
        return list(lang_voices.keys())
    
    def get_supported_languages(self) -> list:
        """Get list of supported language codes"""
        return list(EDGE_TTS_VOICES.keys())


# Global instance
_speech_generator: Optional[SpeechGenerator] = None


def get_speech_generator(audio_dir: str = None) -> SpeechGenerator:
    """Get or create the global speech generator instance"""
    global _speech_generator
    
    if _speech_generator is None:
        _speech_generator = SpeechGenerator(audio_dir)
    
    return _speech_generator


# Convenience async function
async def generate_speech_async(
    text: str,
    voice: str = "nova",
    language_code: str = "en-US",
    speed: float = 1.0
) -> Dict[str, Any]:
    """Async wrapper for speech generation"""
    generator = get_speech_generator()
    return await generator.generate_speech_async(
        text=text,
        voice=voice,
        language_code=language_code,
        speed=speed
    )
