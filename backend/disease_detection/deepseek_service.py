import requests
import json
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class DeepSeekService:
    @staticmethod
    def get_base_url():
        # DeepSeek API URL
        return 'https://api.deepseek.com'
    
    @staticmethod
    def get_treatment_recommendation(disease_name, crop_type):
        """
        Get treatment recommendations for a detected plant disease using DeepSeek API
        """
        try:
            # Construct a prompt for the DeepSeek API
            prompt = f"Provide a concise treatment recommendation for {disease_name} affecting {crop_type} plants. Include: \n"\
                    "1. Brief explanation of the disease\n"\
                    "2. Organic treatment options\n"\
                    "3. Chemical treatment options if necessary\n"\
                    "4. Prevention tips\n"\
                    "Keep the response informative but concise (150-200 words)."

            # Get API key from environment variables
            api_key = os.environ.get('DEEPSEEK_API_KEY', '#')
            if not api_key:
                return {
                    'success': False,
                    'message': 'DeepSeek API key not found'
                }

            # Make the API request to DeepSeek
            response = requests.post(
                f"{DeepSeekService.get_base_url()}/v1/chat/completions",
                headers={
                    'Content-Type': 'application/json',
                    'Authorization': f'Bearer {api_key}',
                },
                json={
                    'model': 'deepseek-chat',  # Update with the appropriate model name
                    'messages': [
                        {
                            'role': 'user',
                            'content': prompt,
                        },
                    ],
                    'temperature': 0.7,
                    'max_tokens': 300,
                }
            )

            if response.status_code == 200:
                json_response = response.json()
                # Extract the treatment recommendation from the response
                recommendation = json_response['choices'][0]['message']['content']
                return {
                    'success': True,
                    'recommendation': recommendation,
                }
            else:
                return {
                    'success': False,
                    'message': f'Failed to get treatment recommendation: {response.status_code}',
                    'details': response.text,
                }
        except Exception as e:
            return {
                'success': False,
                'message': f'Error getting treatment recommendation: {str(e)}',
            }
    
    @staticmethod
    def get_mock_treatment_recommendation(disease_name, crop_type):
        """
        Mock method for testing without actual API calls
        """
        # Simulate network delay in a real application, but not needed here
        # Return a mock response based on the disease name with clear section markers
        if disease_name.lower().find('healthy') != -1:
            recommendation = f"Your {crop_type} plant appears healthy! Continue with regular care:\n\n"\
                "Disease Information:\n"\
                "Your plant is showing signs of good health with no visible disease symptoms.\n\n"\
                "Treatment Recommendations:\n"\
                "1. Water regularly but avoid overwatering\n"\
                "2. Ensure adequate sunlight exposure\n"\
                "3. Apply balanced fertilizer according to plant needs\n"\
                "4. Monitor for early signs of pests or diseases\n\n"\
                "Prevention Measures:\n"\
                "1. Maintain good air circulation around plants\n"\
                "2. Avoid wetting leaves when watering\n"\
                "3. Remove any dead or decaying plant material promptly\n"\
                "4. Inspect plants regularly for early detection of issues"
        elif disease_name.lower().find('blight') != -1:
            recommendation = f"Treatment for {disease_name} on {crop_type}:\n\n"\
                "Disease Information:\n"\
                "Blight is a fungal disease that causes rapid browning and death of plant tissues. It typically appears as dark lesions on leaves that can quickly spread throughout the plant.\n\n"\
                "Treatment Recommendations:\n"\
                "Organic treatments:\n"\
                "1. Remove and destroy infected plant parts immediately\n"\
                "2. Apply copper-based fungicides or neem oil as directed\n"\
                "3. Improve air circulation around plants\n\n"\
                "Chemical options:\n"\
                "1. Apply chlorothalonil or mancozeb-based fungicides\n"\
                "2. Follow label instructions carefully\n"\
                "3. Rotate fungicide types to prevent resistance\n\n"\
                "Prevention Measures:\n"\
                "1. Use disease-resistant varieties when planting\n"\
                "2. Rotate crops annually to break disease cycles\n"\
                "3. Avoid overhead watering to keep foliage dry\n"\
                "4. Space plants properly for good air circulation"
        else:
            recommendation = f"Treatment for {disease_name} on {crop_type}:\n\n"\
                "Disease Information:\n"\
                "This condition affects plant health by damaging leaves and potentially reducing yield. Early detection and treatment are essential for managing this disease effectively.\n\n"\
                "Treatment Recommendations:\n"\
                "Organic treatments:\n"\
                "1. Remove infected plant parts immediately\n"\
                "2. Apply organic fungicides like neem oil or copper soap\n"\
                "3. Introduce beneficial insects if appropriate\n\n"\
                "Chemical options:\n"\
                "1. Targeted fungicides or pesticides may be necessary for severe cases\n"\
                "2. Always follow product instructions and safety guidelines\n"\
                "3. Apply treatments during appropriate weather conditions\n\n"\
                "Prevention Measures:\n"\
                "1. Maintain proper plant spacing for good airflow\n"\
                "2. Water at the base of plants to keep foliage dry\n"\
                "3. Practice crop rotation to prevent disease buildup\n"\
                "4. Use disease-resistant varieties when available"
        
        return {
            'success': True,
            'recommendation': recommendation,
        }