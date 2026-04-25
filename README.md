# C2A Disaster Detection Platform 🚁

This project is a comprehensive end-to-end Machine Learning pipeline for Disaster and Human Detection using UAV imagery. It includes a custom-trained Deep Learning model, a Flask REST API backend, a fully functional Admin Dashboard, and a Flutter mobile application.

## 📌 Project Overview
As per the guidelines, this project covers:
1. **Machine Learning Pipeline (`ml_pipeline/`)**: 
   - Custom Dataset Preprocessing (Resizing, Normalization, Augmentation).
   - A CNN model built entirely from scratch.
   - A Transfer Learning model (MobileNetV2) built manually with a custom head and fine-tuned.
   - Comprehensive evaluation including Accuracy/Loss curves, Precision/Recall/F1-score, and Confusion Matrices.
2. **Backend API (`backend/`)**: A Flask-based RESTful API with SQLite for storing users, detection history, and images.
3. **Admin Dashboard (`admin-dashboard/`)**: A pure HTML/JS web dashboard for monitoring real-time disaster locations using Leaflet maps, viewing uploaded imagery, and comparing the performance metrics of the trained AI models.
4. **Mobile App (`c2a_app/`)**: A lightweight Flutter client that securely authenticates users, allows them to capture or upload UAV images, fetches their live GPS location, and displays real-time AI classification results.

## 📊 Dataset Information
> **Note:** The raw dataset images are intentionally excluded from this GitHub repository via `.gitignore` because of their large size.

To reproduce the training results:
1. Download the Disaster Classification Dataset from [Kaggle / Roboflow]. *(Note: Replace this bracket with your actual dataset link if available, or upload the dataset to Google Drive and put the link here).*
2. Extract the dataset into the root directory under a folder named `dataset/`.
3. Ensure the structure looks like this:
   - `dataset/fire/`
   - `dataset/flood/`
   - `dataset/collapsed_building/`
   - `dataset/normal/`

## 🚀 How to Run the Project

### 1. Training the Machine Learning Model (Optional)
If you wish to re-train the model from scratch:
1. Ensure your dataset is placed in the `dataset/` directory at the root (Classes: `collapsed_building`, `fire`, `flooded_areas`, `normal`, `traffic_incident`).
2. Navigate to `ml_pipeline/`:
   ```bash
   cd ml_pipeline
   ```
3. Install dependencies:
   ```bash
   pip install tensorflow numpy matplotlib seaborn scikit-learn
   ```
4. Run the training script:
   ```bash
   python train_pipeline.py
   ```
   *(This will save the best model as `best_disaster_model.h5` and generate evaluation plots).*

### 2. Running the Backend Server
The backend powers the entire platform.
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install Flask requirements:
   ```bash
   pip install flask flask-cors Pillow numpy tensorflow
   ```
3. Run the server:
   ```bash
   python app.py
   ```
   *The server will start on `http://localhost:5000`.*

### 3. Running the Admin Dashboard
You can run a simple local HTTP server to view the dashboard:
1. Navigate to the dashboard directory:
   ```bash
   cd admin-dashboard
   ```
2. Start the server:
   ```bash
   python -m http.server 8000
   ```
3. Open your browser and go to `http://localhost:8000`. 
   *(Admin Login -> Email: `admin@c2a.ai`, Password: `admin123`)*

### 4. Running the Flutter Mobile App
1. Ensure you have Flutter installed and connected to an emulator, physical device, or Chrome.
2. Navigate to the app directory:
   ```bash
   cd c2a_app
   ```
3. Install packages:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## 🧠 Technologies Used
* **AI / Deep Learning**: TensorFlow, Keras, Scikit-learn, OpenCV.
* **Backend**: Python, Flask, SQLite.
* **Frontend Dashboard**: HTML5, Vanilla JS, CSS3, Leaflet.js, Chart.js.
* **Mobile App**: Flutter, Dart.

## 📝 Evaluation Metrics
The Transfer Learning model (MobileNetV2) achieved a final F1-Score of **~0.90 average** across all disaster classes. Detailed comparison curves and confusion matrices are available in the `ml_pipeline` output and directly inside the "AI Evaluation Report" section of the Admin Dashboard.
