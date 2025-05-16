import os
import json
from django.conf import settings
from inference_sdk import InferenceHTTPClient
from PIL import Image
from io import BytesIO

# Initialize the Roboflow client with API key and URL for disease classification
ROBOFLOW_API_KEY = "xo6mQ5uBlOugUjY9G6ei"
ROBOFLOW_API_URL = "https://serverless.roboflow.com"
DISEASE_CLIENT = InferenceHTTPClient(api_url=ROBOFLOW_API_URL, api_key=ROBOFLOW_API_KEY)

def classify_disease(image_file):
    """
    Classifies plant disease using Roboflow API via InferenceHTTPClient
    Returns a tuple of (success, result_data, message)
    
    The result_data will contain:
    - prediction: The top disease prediction
    - probabilities: A dictionary of all disease probabilities
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
        result = DISEASE_CLIENT.infer(image, model_id="pagdurusa/1")
        
        # Process the result
        if not isinstance(result, dict):
            return False, None, f"API error: Unexpected response type: {type(result)}"
        
        # Check if we have predictions in the expected format
        if 'predictions' in result:
            predictions = result.get('predictions', {})
            
            if not predictions:
                return False, None, "No disease predictions found"
            
            # Format the response for frontend consumption
            # Extract the disease name with highest confidence
            top_disease = None
            max_confidence = 0
            probabilities = {}
            
            # Process predictions based on the API response format
            # The API returns a dictionary with disease names as keys
            for disease_name, prediction_data in predictions.items():
                confidence = prediction_data.get('confidence', 0)
                probabilities[disease_name] = confidence
                
                if confidence > max_confidence:
                    max_confidence = confidence
                    top_disease = disease_name
            
            if top_disease:
                result_data = {
                    'prediction': top_disease,
                    'probabilities': probabilities
                }
                return True, result_data, "Disease classification successful"
            else:
                return False, None, "Could not determine top disease prediction"
        else:
            error_message = "API error: No valid predictions in response"
            if 'error' in result:
                error_message += f" - {result['error']}"
            return False, None, error_message
    
    except Exception as e:
        return False, None, f"Error: {str(e)}"