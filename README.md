<div align="center">

# alvoCam
### Advanced, Privacy-First Camera Module

[![Release](https://img.shields.io/github/v/release/alvin-alvo/alvoCam?style=for-the-badge&color=white)](https://github.com/alvin-alvo/alvoCam/releases/latest)
[![Platform](https://img.shields.io/badge/Platform-Android-050505?style=for-the-badge&logo=android)](https://www.android.com/)
[![Built With](https://img.shields.io/badge/Built%20With-Flutter-050505?style=for-the-badge&logo=flutter)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-GPLv3-white?style=for-the-badge)](LICENSE)

<br/>

</div>

---

## Mission Statement
**alvoCam** is a privacy-focused, minimalist camera application engineered for maximum reliability, hardware efficiency, and a deep integration with Android's Material You dynamic ecosystem. It strips away modern computational photography bloat to focus on capturing raw sensor data alongside optional, cleanly composited telemetry.

Built with an emphasis on **bulletproof lifecycle management** and **asynchronous queueing architecture**. No ads. No background tracking. Just reliable, professional optics.

## Tech Stack
* **Core Engine:** Flutter & Dart
* **Sensor Interface:** `camera` package (Dynamic resolution up to Raw Sensor Max)
* **Compositing Engine:** Dart Isolates (`compute`) & `image` package
* **Telemetry Data:** `geolocator`, `geocoding`
* **Storage Pipeline:** `gal` (Native gallery integration)
* **Design Language:** Material 3 Dynamic Colors (Wallpaper-adaptive)

## Core Features
* **"Fire-and-Forget" Shutter Queue:** Taking a photo immediately captures the raw hardware sensor data and pushes the heavy processing to an asynchronous background queue matrix. The UI unblocks instantly, allowing you to rapid-fire photos without memory crashes or UI lag.
* **Isolate-Powered Watermark Compositing:** When Geolocation is enabled, the app captures a massive 4.0 pixel-ratio UI overlay of your coordinates and seamlessly merges it onto the raw 4K sensor data in the background, retaining perfect 30% width scaling without degrading the camera's original resolution.
* **Material You Integration:** The interface is fully devoid of hardcoded colors, adapting seamlessly to the user's system light/dark mode and active wallpaper theme via the `dynamic_color` package.
* **Privacy-Respecting Map Telemetry:** Geolocation overlays fetch safe, open-source mapping tiles from OpenStreetMap (Mapnik) instead of tracking-heavy proprietary APIs.
* **Hardware-Perfect Viewfinder:** The camera feed dynamically calculates its own constraints (`1 / aspectRatio`) to match the physical sensor, ensuring absolutely zero visual stretching or distortion regardless of the device screen size.
* **Resilient Lifecycle Architecture:** Implements strict `WidgetsBindingObserver` lifecycle states. Hardware resources are gracefully released when the app is backgrounded and forcefully re-acquired upon return, neutralizing dead-thread crashes.

## Installation (APK)
1.  Go to the [Latest Release](https://github.com/alvin-alvo/alvoCam/releases/latest).
2.  Download `alvocam.apk` from the "Assets" section.
3.  Install on any Android device (Android 12+ recommended for Dynamic Colors).
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
