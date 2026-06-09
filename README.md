<div align="center">

# alvoCam
### Advanced, Privacy-First Camera Module

[![Release](https://img.shields.io/badge/Release-v1.1.0-white?style=for-the-badge)](https://github.com/alvin-alvo/alvoCam/releases/latest)
[![Platform](https://img.shields.io/badge/Platform-Android-050505?style=for-the-badge&logo=android)](https://www.android.com/)
[![Built With](https://img.shields.io/badge/Built_With-Flutter-050505?style=for-the-badge&logo=flutter)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-GPLv3-white?style=for-the-badge)](LICENSE)

<br/>

</div>

---

## Mission Statement
**alvoCam** is a privacy-focused, minimalist camera application engineered for maximum reliability, hardware efficiency, and a deep integration with Android's Material You dynamic ecosystem. It strips away modern computational photography bloat to focus on capturing raw sensor data alongside optional, beautifully composited telemetry.

Built with an emphasis on **bulletproof lifecycle management** and **asynchronous queueing architecture**. No ads. No background tracking. Just reliable, professional optics.

---

## Core Features

### "Fire-and-Forget" Shutter Queue
Taking a photo immediately captures the raw hardware sensor data and pushes the heavy processing to an asynchronous background queue matrix (using Isolates). The UI unblocks instantly, allowing you to rapid-fire photos sequentially without out-of-memory crashes or UI lag.

### Master Canvas Compositor
Our dedicated background engine constructs a pristine "Master Canvas" for every shot:
- **Decoupled Resolution:** Watermark text resolution is fully independent of the photo resolution.
- **Retro Preservation:** Low-resolution (e.g., 240p Lo-Fi) shots are elegantly scaled up to a baseline `1080px` width using **Nearest Neighbor interpolation**, retaining a perfect blocky, retro aesthetic without degrading or blurring the metadata text.
- **Clean White Strip:** Metadata is precisely appended to the bottom of your image on a sleek, solid white strip rather than muddying your viewfinder or photo overlay.

### Privacy-Respecting Telemetry
When Geolocation is enabled, the app captures a massive 4.0 pixel-ratio UI layout of your coordinates and seamlessly merges it onto the final image. 
- Features highly-readable sans-serif typography.
- Integrates static map tiles from secure network endpoints, complete with robust offline fallbacks if you're out of cellular range.

### Material 3 & Hardware-Perfect Viewfinder
- **Material You Integration:** The interface dynamically inherits your system light/dark mode and active wallpaper theme via the `dynamic_color` system, eliminating hardcoded constants.
- **Aspect-Perfect Preview:** The camera feed dynamically calculates its constraints (`1 / aspectRatio`) to match the physical hardware sensor exactly, guaranteeing zero visual stretching or distortion regardless of your device's screen size.

### Resilient Architecture
Implements strict `WidgetsBindingObserver` lifecycle states. Hardware resources are gracefully released when the app is backgrounded and forcefully re-acquired upon return, fully neutralizing dead-thread crashes or infinite loading spinners.

---

## Tech Stack
* **Core Engine:** Flutter & Dart
* **Sensor Interface:** `camera` package (Dynamic resolution: Lo-Fi, Standard, High, Ultra, Raw Sensor)
* **Compositing Engine:** Dart Isolates (`compute`) & `image` package
* **Telemetry Data:** `geolocator`, `geocoding`
* **Storage Pipeline:** `gal` (Native gallery integration)
* **Design Language:** Material 3 Dynamic Colors (Wallpaper-adaptive)

---

## Installation (APK)
1.  Go to the [Latest Release](https://github.com/alvin-alvo/alvoCam/releases/latest).
2.  Download `alvocam.apk` from the "Assets" section.
3.  Install on any Android device (Android 12+ recommended for Dynamic Colors).
4.  *Note: You may need to "Allow apps from unknown sources" since this is a developer release.*

---

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

---
<div align="center">
  <i>Built with precision by <b>alvoLabs</b></i>
</div>
