import os
import shutil
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def write_comic_html(html_content: str, image_directory: str = "images") -> str:
    """
    Writes the final HTML content to a file and copies the image assets.
    Args:
        html_content: A string containing the full HTML of the comic.
        image_directory: The source directory where generated images are stored.
    Returns:
        A confirmation message indicating success or failure.
    """
    output_dir = "output"
    images_output_dir = os.path.join(output_dir, image_directory)
    try:
        # Create the main output directory
        if not os.path.exists(output_dir):
            os.makedirs(output_dir, exist_ok=True)
            logger.info(f"Created output directory: {output_dir}")
        
        # Copy the entire image directory to the output folder
        if os.path.exists(image_directory):
            if os.path.exists(images_output_dir):
                shutil.rmtree(images_output_dir)
                logger.info(f"Removed old images from: {images_output_dir}")
            shutil.copytree(image_directory, images_output_dir)
            logger.info(f"Copied images from {image_directory} to {images_output_dir}")
        else:
            logger.error(f"Image directory '{image_directory}' not found.")
            return f"Error: Image directory '{image_directory}' not found."
            
        # Write the HTML file
        html_file_path = os.path.join(output_dir, "comic.html")
        with open(html_file_path, "w") as f:
            f.write(html_content)
        
        logger.info(f"Successfully wrote comic HTML to {html_file_path}")
        return f"Successfully created comic at '{html_file_path}'"
    except Exception as e:
        logger.exception("Failed to write comic HTML or copy assets.")
        return f"An error occurred: {e}"

