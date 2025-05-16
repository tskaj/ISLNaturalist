import os
import json
from django.conf import settings
from inference_sdk import InferenceHTTPClient

# Initialize the Roboflow client with API key and URL
ROBOFLOW_API_KEY = "xo6mQ5uBlOugUjY9G6ei"
ROBOFLOW_API_URL = "https://serverless.roboflow.com"
CLIENT = InferenceHTTPClient(api_url=ROBOFLOW_API_URL, api_key=ROBOFLOW_API_KEY)

def validate_leaf_image(image_file):
    """
    Validates if an image contains a leaf using Roboflow API via InferenceHTTPClient
    Returns a tuple of (is_leaf, confidence, success, message)
    """
    try:
        # Read image file
        image_data = image_file.read()
        
        # Reset file pointer to beginning to ensure it can be read again if needed
        image_file.seek(0)
        
        # Convert image data to base64 string as required by Roboflow API
        import base64
        from io import BytesIO
        from PIL import Image
        
        # Convert bytes to PIL Image
        image = Image.open(BytesIO(image_data))
        
        # Use the InferenceHTTPClient to make the prediction with PIL Image
        # The client handles the API key and URL configuration
        result = CLIENT.infer(image, model_id="my-first-project-mxrml/1")
        
        # Process the result
        # First check if result is a dictionary
        if not isinstance(result, dict):
            # If result is a string, it might be a direct class prediction
            if isinstance(result, str):
                # Common plant/leaf related terms to check against
                leaf_related_terms = ['leaf', 'plant', 'tree', 'foliage', 'frond']
                # Check if the string contains any leaf-related terms
                is_leaf_term = any(term in result.lower() for term in leaf_related_terms)
                
                # If it's a plant/leaf class name, consider it a valid leaf detection
                if is_leaf_term:
                    return True, 0.8, True, f"Leaf detected: {result}"
                else:
                    # It's a class name but not leaf-related
                    return False, 0.0, True, f"Non-leaf object detected: {result}"
            else:
                # Not a string or dict, truly unexpected
                return False, 0.0, False, f"API error: Unexpected response type: {type(result)}"
            
        # Now safely check for predictions
        if 'predictions' in result:
            predictions = result.get('predictions', [])
            
            # Define confidence threshold for leaf detection
            LEAF_CONFIDENCE_THRESHOLD = 0.5
            
            if predictions:
                try:
                    # Handle case where predictions might contain string values
                    if any(isinstance(pred, str) for pred in predictions):
                        # Filter out any non-string predictions
                        string_predictions = [pred for pred in predictions if isinstance(pred, str)]
                        if string_predictions:
                            # Check if any string prediction is leaf-related
                            leaf_related_terms = ['leaf', 'plant', 'tree', 'foliage', 'frond']
                            for pred in string_predictions:
                                if any(term in pred.lower() for term in leaf_related_terms):
                                    return True, 0.8, True, f"Leaf detected: {pred}"
                            # No leaf-related terms found
                            return False, 0.0, True, f"Non-leaf object detected: {string_predictions[0]}"
                    
                    # Get highest confidence prediction
                    highest_confidence = max(predictions, key=lambda x: x.get('confidence', 0) if isinstance(x, dict) else 0)
                    
                    # Ensure highest_confidence is a dictionary before using .get()
                    if not isinstance(highest_confidence, dict):
                        # If it's a string, it might be a direct class prediction
                        if isinstance(highest_confidence, str):
                            # Check if the string contains any leaf-related terms
                            leaf_related_terms = ['leaf', 'plant', 'tree', 'foliage', 'frond']
                            is_leaf_term = any(term in highest_confidence.lower() for term in leaf_related_terms)
                            
                            if is_leaf_term:
                                return True, 0.8, True, f"Leaf detected: {highest_confidence}"
                            else:
                                return False, 0.0, True, f"Non-leaf object detected: {highest_confidence}"
                        else:
                            return False, 0.0, False, f"Error: Prediction is not a dictionary or string: {highest_confidence}"
                        
                    confidence = highest_confidence.get('confidence', 0)
                    class_name = highest_confidence.get('class', '').lower()
                    
                    # For the new model, all predictions are leaf classes (like bereza_povislaya)
                    # So we consider any prediction with sufficient confidence as a leaf
                    is_leaf = confidence >= LEAF_CONFIDENCE_THRESHOLD
                    
                    if is_leaf:
                        return True, confidence, True, f"Leaf detected: {class_name}"
                    else:
                        return False, confidence, True, "No leaf detected with sufficient confidence"
                except Exception as e:
                    return False, 0.0, False, f"Error processing predictions: {str(e)}"
            else:
                return False, 0.0, True, "No objects detected in image"
        else:
            error_message = "API error: No valid response from Roboflow"
            if 'error' in result:
                error_message += f" - {result['error']}"
            return False, 0.0, False, error_message
    
    except Exception as e:
        return False, 0.0, False, f"Error: {str(e)}"