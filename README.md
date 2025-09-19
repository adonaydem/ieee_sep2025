<p align="center">
    <img src="./projects/assets/images/SEP_Logo.png" alt="VisionAid Logo" width="180"/>
</p>

# Radiance: Intelligent Assistive Technology Platform

**Built by Adonay, Sedra Wattar, Sara Walhan and Eng. Wessam Sheiheb**

> *Where cutting-edge AI meets accessibility engineering*

[![Flutter](https://img.shields.io/badge/Flutter-3.32.2+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.13+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge)](LICENSE)

[![Award](https://img.shields.io/badge/IEEE%20UAE%20Software%20Engineering%20Winner-2025-FFD700?style=for-the-badge&logo=ieee&logoColor=white)](https://ieee.org)

Radiance is a **multimodal AI-powered assistive technology platform** that leverages real-time computer vision, natural language processing, and edge computing to provide comprehensive environmental awareness for visually impaired users.

<div align="center">
<img src="./projects/assets/images/object_detection.png" width="180"/>
<img src="./projects/assets/images/text_recognition.png" width="180"/>
<img src="./projects/assets/images/scene_description.png" width="180"/>
<img src="./projects/assets/images/voice_messaging.png" width="180"/>
</div>

## 🎓 Key User Features

- **Object Detection:** Identify hazards in real time using the camera.
- **Text Recognition:** Scan and read printed or digital text via OCR.
- **Scene Analysis:** Gain awareness of the surrounding environment.
- **Voice Communication:** Accessibly, Send and receive voice messages with friends and families.
- **Emergency Features:** Access safety protocols and alerts.
- **Agentic System:** Control the entire app through an intelligent agent, enabling hands-free operation for users who find screen navigation challenging. **The agent can autonomously call tools for object detection, text recognition, scene analysis, as well as provide ***directions*** and location awareness**.

## 🏗️ Architecture Deep Dive

This repo follows a **microservices-oriented architecture** with clear separation of concerns:

```
root/
├── 📱 projects/              # Flutter mobile application (client-side)
│   ├── lib/                  # Dart application logic
│   ├── assets/               # ML models, audio assets, tessdata
│   └── android/ios/linux/    # Platform-specific builds
├── 🔧 sep_backend/           # Python Flask API server (backend services) 🔗 **[Backend](https://github.com/adonaydem/sep_backend/)**  
├── 🛠️  build/                # CMake build artifacts
└── 📋 LICENSE               # Apache 2.0 licensing
```

### 🧠 Core Technology Stack

**Frontend (Mobile)**
- **Flutter 3.7.2+** - Cross-platform UI framework
- **TensorFlow Lite** - On-device ML inference
- **Camera & Permissions** - Real-time video capture
- **Speech-to-Text/TTS** - Voice interaction pipeline
- **Firebase** - Authentication & cloud services

**Backend (API Layer)**
- **Flask** - Lightweight WSGI web framework
- **OpenCV** - Computer vision processing
- **PyTorch/ONNX** - Deep learning model serving
- **Tesseract OCR** - Optical character recognition
- **PostgreSQL** - Persistent data storage

**ML/AI Models**
- **YOLO v11** variants (FP16/FP32/INT8 quantized)
- **ResNet-18 Places365 + BLIP** - Scene description
- **Tesseract** - Multi-language OCR engine
- **Custom voice synthesis** - Audio feedback system


## 🚀 Performance Optimizations

- **Model quantization** - INT8/FP16 variants for mobile efficiency
- **Edge computing** - Hybrid On-device inference reduces latency
- **Async processing** - Non-blocking UI with background tasks
- **Caching strategies** - Local storage for frequently accessed data


## 📱 Android Frontend Setup & Deployment

### Quick Start
```bash
# Navigate to the Flutter project
cd projects/

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

```

### Asset Pipeline
The app utilizes several **pre-trained models** and assets:
- `assets/yolo11n*.tflite` - Object detection models (various quantization levels)
- `assets/tessdata/` - Tesseract language packs
- `assets/audio/` - System sounds and TTS audio
- `assets/images/` - UI assets and tutorial screenshots

## �� Backend Architecture 🔗 **[Backend](https://github.com/adonaydem/sep_backend/)**

The backend is a **Python-based microservices architecture** located in `/sep_backend/`. 


**👉 For detailed backend setup, configuration, and API documentation, navigate to:**
```bash
cd sep_backend/

```

Key backend components include:
- **Flask API server** (`app.py`) - Main application entry point
- **Computer vision pipeline** (`scenedescription.py`, `ocr.py`)
- **Voice processing** (`voice_chat.py`, `chat_utils.py`)
- **Database layer** (`postgres_utils.py`)
- **Geolocation services** (`directions.py`)



## 📜 License & Legal

This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for full details.


---



