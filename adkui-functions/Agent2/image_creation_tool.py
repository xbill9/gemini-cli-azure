import os
import logging
import uuid
from datetime import datetime
from typing import Union, Dict, Any
from dotenv import load_dotenv
from google import genai
from google.genai import types
from google.adk.tools import ToolContext

# Configure logging
# Create a formatter for the log entries
log_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')

# Set up console handler
console_handler = logging.StreamHandler()
console_handler.setFormatter(log_formatter)

# Set up file handler for persistent tool call logging
file_handler = logging.FileHandler('tool_calls.log')
file_handler.setFormatter(log_formatter)

# Configure the root-level logger for this module
logging.basicConfig(
    level=logging.INFO,
    handlers=[console_handler, file_handler]
)
logger = logging.getLogger(__name__)

async def create_image(prompt: str, tool_context: ToolContext) -> Dict[str, Any]:
    """
    Generates an image based on a text prompt using the Google GenAI SDK (Vertex AI).

    Args:
        prompt: The text prompt to generate the image from.
        tool_context: The ADK tool context for saving artifacts.

    Returns:
        A dictionary containing the status, message, and artifact details.
    """
    # Load environment variables. load_dotenv() searches parent directories automatically.
    load_dotenv()
    
    api_key = os.getenv("GOOGLE_API_KEY")
    model_name = os.getenv("IMAGEN_MODEL", "imagen-4.0-fast-generate-001")

    if not api_key:
        error_msg = "Missing GOOGLE_API_KEY in environment."
        logger.error(error_msg)
        return {"status": "error", "message": error_msg}

    logger.info(f"Initiating image generation for prompt: '{prompt[:50]}...' using model: {model_name}")

    try:
        client = genai.Client(
            api_key=api_key,
        )

        # Generate the image
        logger.debug(f"Calling generate_images with config: aspect_ratio=16:9, safety_filter_level=block_low_and_above")
        response = client.models.generate_images(
            model=model_name,
            prompt=prompt,
            config=types.GenerateImagesConfig(
                number_of_images=1,
                aspect_ratio="16:9",
                safety_filter_level="block_low_and_above",
                person_generation="allow_adult",
            ),
        )

        if not response.generated_images:
            logger.warning("Generation call returned success but no images were produced.")
            return {"status": "error", "message": "The model did not generate any images."}

        # Process the generated image
        generated_image = response.generated_images[0]
        image_bytes = generated_image.image.image_bytes
        
        # Create a unique name using timestamp and a short UUID
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        unique_id = str(uuid.uuid4())[:8]
        artifact_name = f"gen_image_{timestamp}_{unique_id}.png"
        
        # Save as ADK artifact
        image_part = types.Part.from_bytes(
            data=image_bytes, 
            mime_type="image/png"
        )
        await tool_context.save_artifact(artifact_name, image_part)
        
        logger.info(f"Successfully saved artifact: {artifact_name}")
        
        return {
            "status": "success",
            "message": f"Image generated and saved as '{artifact_name}'.",
            "artifact_name": artifact_name,
            "timestamp": timestamp,
            "prompt_used": prompt
        }

    except Exception as e:
        error_details = f"Unexpected error during image generation: {str(e)}"
        logger.exception(error_details)
        return {"status": "error", "message": error_details}
