<div align="center">

# alvoCam
### Minimalist, Privacy-First Camera Module

[![Release](https://img.shields.io/github/v/release/alvin-alvo/alvoCam?style=for-the-badge&color=white)](https://github.com/alvin-alvo/alvoCam/releases/latest)
[![Platform](https://img.shields.io/badge/Platform-Android-050505?style=for-the-badge&logo=android)](https://www.android.com/)
[![Built With](https://img.shields.io/badge/Built%20With-Flutter-050505?style=for-the-badge&logo=flutter)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-GPLv3-white?style=for-the-badge)](LICENSE)

<br/>

</div>

---

## Mission Statement
**alvoCam** is a minimalist, privacy-focused camera application engineered for maximum reliability and a true black Material 3 aesthetic. It strips away modern computational photography bloat to focus on raw sensor data, framed perfectly in a 3:4 aspect ratio.

Built with an emphasis on **bulletproof lifecycle management**. No ads. No background tracking. Just reliable optics.

## Tech Stack
* **Core Engine:** Flutter & Dart
* **Sensor Interface:** `camera` package (High-res capture)
* **Storage Pipeline:** `gal` (Native gallery integration)
* **Design Language:** True Black Material 3

## Core Features
* **Zero-Lag Shutter:** Direct capture-to-disk pipeline with physical haptic and visual feedback.
* **Resilient Architecture:** Implements strict `WidgetsBindingObserver` lifecycle states. Hardware resources are gracefully released when the app is backgrounded and re-acquired upon return, preventing locks or crashes.
* **Privacy First:** Explicit runtime permission handling. No internet permissions required for operation.
* **Aspect-Perfect Viewfinder:** The camera feed is strictly constrained to a 3:4 ratio to eliminate stretching across different hardware screen sizes.
* **Minimalist HUD:** Clean, true black interface with crisp white iconography. No custom fonts, no unnecessary distractions.

## Installation (APK)
1.  Go to the [Latest Release](https://github.com/alvin-alvo/alvoCam/releases/latest).
2.  Download `alvocam.apk` from the "Assets" section.
3.  Install on any Android device (Android 10+ recommended).
4.  *Note: You may need to "Allow apps from unknown sources" since this is a developer release.*

## Local Development Setup

### Prerequisites
* Flutter SDK (3.x.x)
* Android Studio / VS Code
* Java JDK 17

### Build Instructions
```bash
# 1. Clone the repository
git clone https://github.com/alvin-alvo/alvoCam.git

# 2. Navigate to directory
cd alvoCam

# 3. Install dependencies
flutter pub get

# 4. Run on device
flutter run
```
