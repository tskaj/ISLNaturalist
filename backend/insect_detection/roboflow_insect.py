import os
import json
from django.conf import settings
from inference_sdk import InferenceHTTPClient
from PIL import Image
from io import BytesIO

# Initialize the Roboflow client with API key and URL for insect detection
ROBOFLOW_API_KEY = "xo6mQ5uBlOugUjY9G6ei"  # You should move this to environment variables
ROBOFLOW_API_URL = "https://serverless.roboflow.com"
INSECT_CLIENT = InferenceHTTPClient(api_url=ROBOFLOW_API_URL, api_key=ROBOFLOW_API_KEY)

def detect_insect_species(image_file):
    """
    Detects insect species using Roboflow API via InferenceHTTPClient
    Returns a tuple of (success, result_data, message)
    
    The result_data will contain:
    - species: The detected insect species
    - confidence: Confidence score of the detection
    - detections: Full detection data from Roboflow
    """
    try:
        # Read image file
        image_data = image_file.read()
        
        # Reset file pointer to beginning to ensure it can be read again if needed
        image_file.seek(0)
        
        # Convert bytes to PIL Image
        image = Image.open(BytesIO(image_data))
        
        # Use the InferenceHTTPClient to make the prediction with PIL Image
        # The client handles the API key and URL configuration
        # Using the model ID from the provided URL
        result = INSECT_CLIENT.infer(image, model_id="insect_detect_classification_v2/1")
        
        # Process the result
        if not isinstance(result, dict):
            return False, None, f"API error: Unexpected response type: {type(result)}"
        
        # Check if we have predictions in the expected format
        if 'predictions' in result:
            predictions = result.get('predictions', [])
            
            if not predictions:
                return False, None, "No insect species detected"
            
            # Format the response for frontend consumption
            # Extract the species with highest confidence
            top_detection = max(predictions, key=lambda x: x.get('confidence', 0))
            species = top_detection.get('class', 'Unknown')
            confidence = top_detection.get('confidence', 0.0)
            
            result_data = {
                'species': species,
                'confidence': confidence,
                'detections': predictions
            }
            
            return True, result_data, "Insect species detected successfully"
        else:
            return False, None, "API error: No predictions in response"
            
    except Exception as e:
        return False, None, f"Error detecting insect species: {str(e)}"