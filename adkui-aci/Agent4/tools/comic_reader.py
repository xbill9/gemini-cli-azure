import os
import logging
import base64
import re
from google.adk.tools import ToolContext
from google.genai import types

logger = logging.getLogger(__name__)

def list_generated_comics() -> str:
    """
    Lists the files in the 'output' directory to see what's been generated.
    Returns:
        A string listing all files in the output folder.
    """
    output_dir = "output"
    if not os.path.exists(output_dir):
        return "The 'output' directory does not exist yet. Run Agent3 first."
    
    files = os.listdir(output_dir)
    if not files:
        return "The 'output' directory is empty."
    
    # Also list images if they exist
    images_dir = os.path.join(output_dir, "images")
    image_list = ""
    if os.path.exists(images_dir):
        images = [f for f in os.listdir(images_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
        if images:
            image_list = "\n\nImages in 'output/images/':\n- " + "\n- ".join(images)
    
    return "Files in the 'output' directory:\n- " + "\n- ".join(files) + image_list

def get_comic_summary() -> str:
    """
    Reads the comic HTML and extracts a plain text summary of the story and panels.
    Returns:
        A string summary of the comic.
    """
    html_path = os.path.join("output", "comic.html")
    if not os.path.exists(html_path):
        return "Error: 'output/comic.html' was not found."
    
    try:
        with open(html_path, "r") as f:
            content = f.read()
        
        # Simple extraction of text - stripping tags
        # This is a bit naive but should give a sense of the story
        text_content = re.sub('<[^<]+?>', '\n', content)
        # Clean up whitespace
        lines = [line.strip() for line in text_content.split('\n') if line.strip()]
        summary = "\n".join(lines[:50]) # Limit to first 50 lines
        
        return f"Summary of 'comic.html':\n\n{summary}"
    except Exception as e:
        return f"Error reading file: {e}"

async def export_comic_to_artifacts(tool_context: ToolContext) -> str:
    """
    Creates a self-contained version of the comic and saves all assets 
    as ADK artifacts for immediate viewing in the UI.
    
    This includes:
    1. Saving all individual panel images as artifacts.
    2. Generating a self-contained HTML (with embedded base64 images) as an artifact.
    3. Generating a Markdown version of the comic as an artifact.
    
    Returns:
        A confirmation message with instructions on how to view.
    """
    output_dir = "output"
    images_dir = os.path.join(output_dir, "images")
    html_path = os.path.join(output_dir, "comic.html")
    
    if not os.path.exists(output_dir):
        return "Error: 'output/' directory not found. Please run Agent3 first."

    results = []
    
    # 1. Save individual images as artifacts
    images = []
    if os.path.exists(images_dir):
        images = sorted([f for f in os.listdir(images_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg'))])
    
    for image_name in images:
        image_path = os.path.join(images_dir, image_name)
        try:
            with open(image_path, "rb") as f:
                image_bytes = f.read()
            
            mime_type = "image/png" if image_name.lower().endswith(".png") else "image/jpeg"
            image_part = types.Part.from_bytes(data=image_bytes, mime_type=mime_type)
            await tool_context.save_artifact(f"panel_{image_name}", image_part)
        except Exception as e:
            logger.error(f"Failed to save image artifact {image_name}: {e}")

    results.append(f"Saved {len(images)} panels as artifacts.")

    # 2. Create self-contained HTML (with base64 images)
    if os.path.exists(html_path):
        try:
            with open(html_path, "r") as f:
                html_content = f.read()
            
            # Replace image sources with base64 data
            def embed_image(match):
                img_src = match.group(1)
                # Resolve path - assuming src is relative to output/
                # e.g. src="images/panel_1.png"
                full_img_path = os.path.join(output_dir, img_src)
                if os.path.exists(full_img_path):
                    with open(full_img_path, "rb") as img_f:
                        img_data = base64.b64encode(img_f.read()).decode('utf-8')
                    ext = os.path.splitext(img_src)[1].lower().strip('.')
                    return f'src="data:image/{ext};base64,{img_data}"'
                return match.group(0) # Keep original if not found

            embedded_html = re.sub(r'src=["\']([^"\']+\.(?:png|jpg|jpeg))["\']', embed_image, html_content)
            
            html_artifact = types.Part.from_bytes(
                data=embedded_html.encode('utf-8'), 
                mime_type="text/html"
            )
            await tool_context.save_artifact("view_full_comic.html", html_artifact)
            results.append("Generated self-contained HTML artifact: 'view_full_comic.html'")
        except Exception as e:
            logger.error(f"Failed to create self-contained HTML: {e}")
            results.append(f"Failed to generate self-contained HTML: {e}")

    # 3. Create a Markdown version
    try:
        # Simple markdown conversion
        md_content = "# Comic Book Preview\n\n"
        md_content += "This is a preview of your generated comic book. Check the 'Artifacts' tab to see the individual panels and the full HTML view.\n\n"
        
        if os.path.exists(html_path):
            with open(html_path, "r") as f:
                content = f.read()
            # Extract basic text for the MD
            text_summary = re.sub('<[^<]+?>', '\n', content)
            md_content += "## Story Summary\n"
            md_content += "\n".join([line.strip() for line in text_summary.split('\n') if line.strip()][:30])
        
        md_artifact = types.Part.from_bytes(
            data=md_content.encode('utf-8'),
            mime_type="text/markdown"
        )
        await tool_context.save_artifact("comic_preview.md", md_artifact)
        results.append("Generated Markdown summary artifact: 'comic_preview.md'")
    except Exception as e:
        logger.error(f"Failed to create MD artifact: {e}")

    return "\n".join(results) + "\n\nYou can now view the comic directly in the ADK UI's 'Artifacts' pane. Look for 'view_full_comic.html' for the complete layout or 'comic_preview.md' for a summary."
