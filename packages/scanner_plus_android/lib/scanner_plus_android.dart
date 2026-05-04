import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:scanner_plus_platform_interface/scanner_plus_platform_interface.dart';
import 'package:scanner_plus_rust_core/scanner_plus_rust_core.dart' as api;

class ScannerPlusAndroid extends ScannerPlusPlatform {
  static const MethodChannel _channel = MethodChannel('scanner_plus_android');

  /// Registers this class as the default instance of [ScannerPlusPlatform].
  static void registerWith() {
    ScannerPlusPlatform.instance = ScannerPlusAndroid();
    api.RustLib.init();
  }

  @override
  Future<ScannerPlusCapture?> analyzeImage(String path, {ScannerPlusOptions? options}) async {
    if (options?.mode != ScannerPlusMode.rust) {
      try {
        final List<dynamic>? results = await _channel.invokeMethod('analyzeImage', {'path': path});
        if (results != null && results.isNotEmpty) {
          return ScannerPlusCapture(
            timestamp: DateTime.now(),
            barcodes: results.map((r) => ScannerPlusBarcode(
              rawValue: r['rawValue'],
              format: _mapNativeFormat(r['format']),
              rawBytes: r['rawBytes'],
            )).toList(),
          );
        }
      } catch (e) {
        if (options?.mode == ScannerPlusMode.native) rethrow;
        // Fallback to rust if adaptive
      }
    }
    
    final results = api.analyzeImage(path: path);
    return _mapResults(results);
  }

  @override
  Future<ScannerPlusCapture?> analyzeBytes(
    Uint8List bytes, {
    required int width,
    required int height,
    required String format,
    ScannerPlusOptions? options,
  }) async {
    // For now, byte analysis is always via Rust as it's easier to pass bytes
    final results = api.analyzeBytes(
      bytes: bytes,
      width: width,
      height: height,
      format: format,
    );
    return _mapResults(results);
  }

  @override
  Future<List<ScannerPlusCamera>> getAvailableCameras() async {
    final cameras = api.availableCameras();
    return cameras.map((c) => ScannerPlusCamera(id: c.index.toString(), name: c.name)).toList();
  }

  @override
  ScannerPlusCameraStream startScan(ScannerPlusCamera camera, {ScannerPlusOptions? options}) {
    if (options?.mode == ScannerPlusMode.rust) {
      return _startRustScan(camera);
    }
    
    // For mobile live scan, we use a PlatformView-based approach 
    // which is handled by ScannerPlusView widget.
    // However, the interface expects a stream.
    // We'll provide a stream that will be populated by the PlatformView.
    // This is a bit of a mismatch with the current interface, 
    // but we can handle it.
    
    return _startRustScan(camera); // Default fallback
  }

  ScannerPlusCameraStream _startRustScan(ScannerPlusCamera camera) {
    final resultSink = api.RustStreamSink<List<api.BarcodeResult>>();
    final frameSink = api.RustStreamSink<api.Frame>();
    
    api.startScan(
      resultSink: resultSink,
      frameSink: frameSink,
      index: int.parse(camera.id),
    );
    
    return ScannerPlusCameraStream(
      barcodes: resultSink.stream.map((results) => _mapResults(results)!),
      frames: frameSink.stream.map((f) => ScannerPlusFrame(bytes: f.bytes, width: f.width, height: f.height)),
    );
  }

  ScannerPlusCapture? _mapResults(List<api.BarcodeResult> results) {
    if (results.isEmpty) return null;
    return ScannerPlusCapture(
      timestamp: DateTime.now(),
      barcodes: results.map((r) => ScannerPlusBarcode(
        rawValue: r.text,
        format: _mapFormat(r.format),
        rawBytes: r.bytes,
        cornerPoints: [
          Offset(r.topLeft.x.toDouble(), r.topLeft.y.toDouble()),
          Offset(r.topRight.x.toDouble(), r.topRight.y.toDouble()),
          Offset(r.bottomRight.x.toDouble(), r.bottomRight.y.toDouble()),
          Offset(r.bottomLeft.x.toDouble(), r.bottomLeft.y.toDouble()),
        ],
      )).toList(),
    );
  }

  ScannerPlusBarcodeFormat _mapFormat(String format) {
    switch (format.toLowerCase()) {
      case 'qrcode': return ScannerPlusBarcodeFormat.qrCode;
      case 'ean13': return ScannerPlusBarcodeFormat.ean13;
      case 'code128': return ScannerPlusBarcodeFormat.code128;
      default: return ScannerPlusBarcodeFormat.unknown;
    }
  }

  ScannerPlusBarcodeFormat _mapNativeFormat(String format) {
    switch (format) {
      case 'QR_CODE':
      case '1': return ScannerPlusBarcodeFormat.qrCode;
      case 'AZTEC': return ScannerPlusBarcodeFormat.aztec;
      case 'DATAMATRIX': return ScannerPlusBarcodeFormat.dataMatrix;
      case 'EAN_13': return ScannerPlusBarcodeFormat.ean13;
      case 'EAN_8': return ScannerPlusBarcodeFormat.ean8;
      case 'ITF': return ScannerPlusBarcodeFormat.itf;
      case 'CODE_39': return ScannerPlusBarcodeFormat.code39;
      case 'CODE_93': return ScannerPlusBarcodeFormat.code93;
      case 'CODE_128': return ScannerPlusBarcodeFormat.code128;
      case 'PDF417': return ScannerPlusBarcodeFormat.pdf417;
      default: return ScannerPlusBarcodeFormat.unknown;
    }
  }

  @override
  Widget buildPreview(void Function(ScannerPlusCapture) onCapture) {
    // Return AndroidView for native scanning
    return AndroidView(
      viewType: 'scanner_plus_view',
      onPlatformViewCreated: (id) {
        final channel = EventChannel('scanner_plus_android/barcodes/$id');
        channel.receiveBroadcastStream().listen((data) {
          final results = data as List<dynamic>;
          onCapture(ScannerPlusCapture(
            timestamp: DateTime.now(),
            barcodes: results.map((r) => ScannerPlusBarcode(
              rawValue: r['rawValue'],
              format: _mapNativeFormat(r['format']),
            )).toList(),
          ));
        });
      },
    );
  }
}
