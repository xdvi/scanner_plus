# scanner_plus

A high-performance, federated Flutter plugin for barcode and QR code scanning. Built with a unified Rust core (ZXing) and native platform support (ML Kit / Apple Vision).

## Features

- 🚀 **High Performance**: Native decoding on Android (ML Kit), iOS and macOS (Apple Vision).
- 🦀 **Rust Powered**: High-speed, consistent decoding on Windows and Linux, with fallback support on other platforms via a unified Rust core.
- 🌍 **Universal**: Full support for Android, iOS, Windows, Linux, macOS, and Web.
- 🛠️ **Adaptive Strategy**: Automatically uses the best available decoder for the platform, with manual override support.
- ✨ **Professional UX**: Includes a customizable scanning overlay with animated line and haptic feedback.

## Supported Platforms

| Platform | Decoder | Status |
| :--- | :--- | :--- |
| **Android** | ML Kit / Rust | ✅ Supported |
| **iOS** | Apple Vision / Rust | ✅ Supported |
| **Windows** | Rust (ZXing) | ✅ Supported |
| **Linux** | Rust (ZXing) | ✅ Supported |
| **macOS** | Rust (ZXing) | ✅ Supported |
| **Web** | Browser API / JS | ✅ Supported |

## Getting Started

### 1. Add dependency

```yaml
dependencies:
  scanner_plus: ^0.0.1
```

### 2. Platform Configuration

#### Android
Add the camera permission to your `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

#### iOS
Add the camera usage description to your `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes.</string>
```

### 3. Usage

```dart
import 'package:scanner_plus/scanner_plus.dart';

// 1. Initialize Controller
final controller = ScannerPlusController();
await controller.initialize();

// 2. Listen for captures
controller.captures.listen((capture) {
  print('Detected: ${capture.barcodes.first.rawValue}');
});

// 3. Display Scanner View
@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      ScannerPlusView(controller: controller),
      const ScannerPlusOverlay(borderColor: Colors.blue),
    ],
  );
}

// 4. Start scanning
controller.start();
```

## License

MIT
