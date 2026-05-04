import 'dart:typed_data';
import 'dart:ui';

/// Supported image formats for the barcode scanner
enum ScannerPlusImageFormat {
  rgba8888,
  bgra8888,
  yuv420,
  nv21,
  unknown,
}

/// Supported barcode formats
enum ScannerPlusBarcodeFormat {
  qrCode,
  dataMatrix,
  aztec,
  pdf417,
  code128,
  code39,
  code93,
  ean13,
  ean8,
  upcA,
  upcE,
  itf,
  codabar,
  unknown,
}

/// A captured frame result
class ScannerPlusCapture {
  final List<ScannerPlusBarcode> barcodes;
  final Size? imageSize;
  final DateTime timestamp;

  ScannerPlusCapture({
    required this.barcodes,
    this.imageSize,
    required this.timestamp,
  });
}

/// A single scanned barcode
class ScannerPlusBarcode {
  final String? rawValue;
  final Uint8List? rawBytes;
  final ScannerPlusBarcodeFormat format;
  final Rect? boundingBox;
  final List<Offset>? cornerPoints;

  ScannerPlusBarcode({
    this.rawValue,
    this.rawBytes,
    required this.format,
    this.boundingBox,
    this.cornerPoints,
  });
}

/// Decoder modes for mobile platforms
enum ScannerPlusMode {
  /// Use the best available native API (ML Kit on Android, Apple Vision on iOS)
  native,
  /// Force usage of the Rust-based ZXing decoder
  rust,
  /// Try native first, fallback to rust if native fails or is unavailable
  adaptive,
}

/// Configuration options for the scanner
class ScannerPlusOptions {
  final List<ScannerPlusBarcodeFormat> formats;
  final bool returnImageBytes;
  final Rect? scanWindow;
  final ScannerPlusMode mode;

  const ScannerPlusOptions({
    this.formats = const [ScannerPlusBarcodeFormat.qrCode],
    this.returnImageBytes = false,
    this.scanWindow,
    this.mode = ScannerPlusMode.adaptive,
  });
}
