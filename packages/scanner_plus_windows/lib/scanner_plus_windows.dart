import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:scanner_plus_platform_interface/scanner_plus_platform_interface.dart';
import 'package:scanner_plus_rust_core/scanner_plus_rust_core.dart' as api;

class ScannerPlusWindows extends ScannerPlusPlatform {
  /// Registers this class as the default instance of [ScannerPlusPlatform].
  static void registerWith() {
    ScannerPlusPlatform.instance = ScannerPlusWindows();
    api.RustLib.init();
  }

  @override
  Future<ScannerPlusCapture?> analyzeImage(String path, {ScannerPlusOptions? options}) async {
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
}
