import os
import numpy as np
import onnxruntime as ort
from PIL import Image
import json

class ModelManager:
    def __init__(self):
        self.models = {}
        self.labels = {}
        self.models_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'models')
        self._load_models()
    
    def _load_models(self):
        # Load tomato model (your custom model)
        tomato_model_path = os.path.join(self.models_dir, 'tomato_disease_model.onnx')
        tomato_labels_path = os.path.join(self.models_dir, 'tomato_labels.json')
        
        if os.path.exists(tomato_model_path) and os.path.exists(tomato_labels_path):
            self.models['tomato'] = ort.InferenceSession(tomato_model_path)
            with open(tomato_labels_path, 'r') as f:
                self.labels['tomato'] = json.load(f)
        
        # Load other crop models (pre-trained)
        crops = ['apple', 'corn', 'potato', 'rice']
        for crop in crops:
            model_path = os.path.join(self.models_dir, f'{crop}_disease_model.onnx')
            labels_path = os.path.join(self.models_dir, f'{crop}_labels.json')
            
            if os.path.exists(model_path) and os.path.exists(labels_path):
                self.models[crop] = ort.InferenceSession(model_path)
                with open(labels_path, 'r') as f:
                    self.labels[crop] = json.load(f)
    
    def preprocess_image(self, image_path, target_size=(224, 224)):
        """Preprocess the image for model input"""
        img = Image.open(image_path).convert('RGB')
        img = img.resize(target_size)
        img_array = np.array(img) / 255.0
        return np.expand_dims(img_array, axis=0).astype(np.float32)
    
    def predict(self, image_path, crop_type=None):
        """Make a prediction for the given image"""
        if crop_type and crop_type not in self.models:
            return {"error": f"Model for {crop_type} not available"}
        
        # If crop type is not specified, try to detect it automatically
        if not crop_type:
            # For now, default to tomato if crop type is not specified
            crop_type = 'tomato'
        
        # Preprocess the image
        input_data = self.preprocess_image(image_path)
        
        # Get the model and labels for the crop type
        model = self.models[crop_type]
        labels = self.labels[crop_type]
        
        # Run inference
        input_name = model.get_inputs()[0].name
        output_name = model.get_outputs()[0].name
        predictions = model.run([output_name], {input_name: input_data})[0]
        
        # Process the predictions
        probabilities = predictions[0].tolist()
        predicted_class = np.argmax(predictions[0])
        predicted_label = labels[str(predicted_class)]
        
        # Create a dictionary of class labels and their probabilities
        prob_dict = {labels[str(i)]: float(prob) for i, prob in enumerate(probabilities)}
        
        return {
            "prediction": predicted_label,
            "probabilities": prob_dict,
            "crop_type": crop_type
        }

# Singleton instance
model_manager = ModelManager()