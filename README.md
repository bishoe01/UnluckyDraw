
# 🎲 UnluckyDraw

> Who will face the penalty? A fun lottery app that determines fate with just one photo

Struggling to decide who pays the bill or runs errands when you're with friends? **UnluckyDraw** solves this fairly and entertainingly! Simply take a group photo or select one from your gallery, and our face recognition technology automatically finds participants, then selects the chosen one through a thrilling roulette system.

## ✨ Key Features

### 📸 Smart Face Recognition
- **Automatic Face Detection**: Precise face recognition using Apple's Vision Framework
- **Manual Editing**: Add or adjust faces manually if any are missed
- **Real-time Preview**: Instantly view and modify detected faces

### 🎰 Thrilling Roulette Experience
- **3-Phase Process**: Dramatic progression through Scan → Targeting → Final Selection
- **Real-time Feedback**: Immersive experience with haptic feedback and sound effects
- **Visual Effects**: Spectacular neon-style animations

### 🎮 Intuitive Usage
1. 📷 Take a photo or select from gallery
2. ✏️ Review and edit face detection results
3. 🎲 Spin the roulette
4. 💀 Check results and share

## 📱 Screenshots

| Home Screen | Face Detection | Roulette | Results |
|:---:|:---:|:---:|:---:|
| ![Home](screenshots/home.png) | ![Detection](screenshots/detection.png) | ![Roulette](screenshots/roulette.png) | ![Results](screenshots/result.png) |
| Sleek dark-themed home | Accurate face detection & editing | 3-phase dramatic roulette | The moment of truth |



## 🚀 Getting Started

### Requirements
- iOS 18.5 or later
- Xcode 16.4 or later
- iPhone (recommended)


### 🔑 Permissions Required
The app requires the following permissions:
- **Camera Access**: For taking new group photos
- **Photo Library Access**: For selecting existing photos

## 🛠 Technical Features

### Architecture
- **MVVM Pattern**: Reactive architecture using SwiftUI + Combine
- **Modularization**: Clean code structure separated by functionality
- **State Management**: Consistent state management through ObservableObject

### Core Tech Stack
```
🎨 UI Framework        → SwiftUI
🤖 Face Recognition    → Vision Framework  
📷 Camera/Media        → AVFoundation
🖼️ Image Processing   → CoreImage
🔊 Sound Effects       → AudioToolbox
⚡ State Management    → Combine
```

### Performance Optimization
- **GPU Acceleration**: Utilizing GPU for face recognition and image processing
- **Memory Management**: Memory efficiency considerations for large image processing
- **Battery Optimization**: Activating camera and processing features only when needed

## 📁 Project Structure

```
UnluckyDraw/
├── 📱 UnluckyDrawApp.swift        # App entry point
├── 🏠 ContentView.swift           # Main container
├── 🎮 Views/                      # UI Components
│   ├── HomeView.swift             # Home screen
│   ├── PhotoDrawView.swift        # Photo selection flow
│   ├── FaceDetectionView.swift    # Face detection screen
│   ├── FaceReviewIntegratedView.swift # Integrated review screen
│   ├── RouletteView.swift         # Roulette screen
│   ├── ResultView.swift           # Results screen
│   └── Components/                # Reusable components
├── 🎛️ Controllers/               # Business Logic
│   ├── FaceDetectionController.swift  # Face detection controller
│   └── RouletteController.swift       # Roulette logic controller
├── 📊 Models/                     # Data Models
│   ├── DetectedFace.swift         # Face data model
│   ├── EditableFace.swift         # Editable face model
│   └── DrawMode.swift             # Draw mode definitions
└── 🔧 Utils/                      # Utilities
    ├── ImageSourceManager.swift   # Image source management
    ├── ImageSaveManager.swift     # Image save management
    ├── SoundManager.swift         # Sound effects management
    └── Extensions.swift           # Extension functions
```

## 🎮 Usage Guide

### Step 1: Prepare Photo
- **📷 New Capture**: Use "CAPTURE FATE" button to take a group photo
- **🖼️ Gallery Selection**: Use "CHOOSE VICTIMS" button to select existing photo

### Step 2: Review Faces
- Check automatically detected faces
- Add missed faces manually using the "+" button
- Remove unnecessary faces by long-pressing

### Step 3: Fate's Roulette
- Roulette starts automatically when ready
- **Phase 1**: ⚡ High-speed scan
- **Phase 2**: 🎯 Target narrowing
- **Phase 3**: 💀 Final selection

### Step 4: Check Results
- View the unlucky chosen one
- Save or share results as photo
- Start new game with "Try Again" button

## ⚡ Core Features

### 🧠 Smart Face Recognition
```swift
// Advanced image preprocessing for improved recognition
private func preprocessImageForDetection(_ cgImage: CGImage) -> CGImage {
    // 5-stage image enhancement pipeline
    // 1. Color correction → 2. Sharpening → 3. Noise reduction 
    // 4. Gamma adjustment → 5. Color temperature normalization
}
```

### 🎨 Immersive UI/UX
- **Dark Theme**: Futuristic neon-sign style design
- **Smooth Animations**: Natural transitions with SwiftUI animations
- **Haptic Feedback**: Vivid responses with every touch

### 🎵 Sound System
```swift
// Contextual sound effects
func playSpinSound()     // During roulette spin
func playCaughtSound()   // Result announcement
func playCompleteSound() // Completion
```

## 🔧 Developer Guide

### Extending Core Components

**Adding New Face Recognition Algorithm:**
```swift
// FaceDetectionController.swift
private func setupFaceDetection() {
    // Vision Framework configuration
    faceDetectionRequest?.revision = VNDetectFaceRectanglesRequestRevision3
    faceDetectionRequest?.usesCPUOnly = false // GPU acceleration
}
```

**Implementing Custom Roulette Effects:**
```swift
// RouletteController.swift 
func startRoulette(with faces: [DetectedFace]) {
    // 3-phase system for building tension
    self.currentPhase = 1 // High-speed scan
    // → 2 (Targeting) → 3 (Final selection)
}
```

### Build Configuration
- **Deployment Target**: iOS 18.5+
- **Bundle ID**: `com.Finn.UnluckyDraw`
- **Required Capabilities**: Camera, Photo Library

## 📋 Known Issues

- [ ] **Simulator Limitations**: Camera functionality works only on actual devices
- [ ] **Memory Usage**: Possible increased memory usage with high-resolution image processing
- [ ] **Face Recognition Accuracy**: Reduced accuracy in extremely dark or blurry photos

## 🎯 Future Plans

### v1.1 Upcoming Features
- [ ] 🌍 **Multi-language Support** (English, Japanese, Chinese)
- [ ] 📊 **Statistics Feature** (Game records, win rates, etc.)
- [ ] 🎨 **Theme Selection** (Light mode, custom themes)
- [ ] 🔊 **Custom Sounds** (User-defined sound effects)

### v1.2 Upcoming Features
- [ ] 👥 **Group Management** (Save frequent members)
- [ ] 🏆 **Challenges** (Fun mission system)
- [ ] 📱 **Widget Support** (Quick launch from home screen)

## 🤝 Contributing

Help make UnluckyDraw even more fun!

### How to Contribute
1. **Issue Reports**: Submit bugs or improvement ideas to Issues
2. **Pull Requests**: Code improvements or new feature implementations
3. **Feedback**: Share user reviews or suggestions

### Development Guidelines
- Follow Swift coding conventions
- Write clear commit messages in Korean or English
- Submit new features with test code

```bash
# Create development branch
git checkout -b feature/new-feature-name

# Commit and push
git commit -m "✨ New feature: description"
git push origin feature/new-feature-name
```

## 📄 License

This project is distributed under the **MIT License**.

You are free to use, modify, and distribute, including commercial use. Please maintain original author attribution.

---

## ❤️ Credits

**Developer**: [bishoe](https://github.com/bishoe)  
**Development Period**: June 2025  
**Tech Stack**: SwiftUI, Vision Framework, AVFoundation

### Open Source Used
- **Apple Vision Framework**: Face recognition engine
- **SwiftUI**: Native UI framework
- **AVFoundation**: Camera and media processing

---

**🎲 Experience fair and fun draws with UnluckyDraw!**

> "Fate cannot be avoided, but at least it can be determined fairly."

---

### 📞 Contact

- **Bug Reports**: [Issues Page](https://github.com/your-username/UnluckyDraw/issues)
- **Feature Suggestions**: [Discussions](https://github.com/your-username/UnluckyDraw/discussions)
- **Email**: bishoe01@kakao.com

**Starring ⭐ this repo would be a great help for development!**

