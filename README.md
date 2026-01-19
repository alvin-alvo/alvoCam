<div align="center">

# alvoCam
### SYSTEM: ONLINE // RETRO FUTURISM CAMERA MODULE

[![Release](https://img.shields.io/github/v/release/alvin-alvo/alvoCam?style=for-the-badge&color=39FF14)](https://github.com/alvin-alvo/alvoCam/releases)
[![Platform](https://img.shields.io/badge/Platform-Android-050505?style=for-the-badge&logo=android)](https://www.android.com/)
[![Built With](https://img.shields.io/badge/Built%20With-Flutter-050505?style=for-the-badge&logo=flutter)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-GPLv3-amber?style=for-the-badge)](LICENSE)

<br/>

</div>

---

##  Mission Statement
**alvoCam** is a minimalist, privacy-focused camera application designed with a **Retro-Futuristic** interface. It strips away modern computational photography bloat to focus on the raw sensor data, framed by a "Rule of Thirds" cyber-grid.

Built for the **System Era**. No ads. No tracking. Just optics.

##  Tech Stack
* **Core Engine:** Flutter & Dart
* **Architecture:** Clean Architecture (UI / Core / Logic)
* **Sensor Interface:** `camera` package (High-res capture)
* **Storage Pipeline:** `gal` (Native gallery integration)
* **Typography:** Google Fonts (`Orbitron`)

##  Features
* **Zero-Lag Shutter:** Direct capture-to-disk pipeline.
* **Cyber-HUD:** Custom drawn "Rule of Thirds" grid overlay.
* **Privacy First:** No internet permissions required for operation.
* **Gallery Integration:** Seamless save to Android "DCIM" folder.
* **Aesthetic:** High-contrast `Amber` and `Neon Green` on `Void Black`.

##  Installation (APK)
1.  Go to the [Releases Page](https://github.com/alvin-alvo/alvoCam/releases).
2.  Download the latest `alvocam.apk`.
3.  Install on any Android device (Android 10+ recommended).
4.  *Note: You may need to "Allow apps from unknown sources" since this is a developer release.*

##  Local Development Setup

### Prerequisites
* Flutter SDK (3.x.x)
* Android Studio / VS Code
* Java JDK 17

### Build Instructions
```bash
# 1. Clone the repository
git clone [https://github.com/alvin-alvo/alvoCam.git](https://github.com/alvin-alvo/alvoCam.git)

# 2. Navigate to directory
cd alvoCam

# 3. Install dependencies
flutter pub get

# 4. Run on device
flutter run