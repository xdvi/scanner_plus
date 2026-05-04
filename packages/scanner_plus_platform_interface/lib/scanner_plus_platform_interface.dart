import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'src/models.dart';

export 'src/models.dart';

abstract class ScannerPlusPlatform extends PlatformInterface {
  /// Constructs a ScannerPlusPlatform.
  ScannerPlusPlatform() : super(token: _token);

  static final Object _token = Object();

  static ScannerPlusPlatform _instance = _DefaultScannerPlusPlatform();

  /// The default instance of [ScannerPlusPlatform] to use.
  ///
  /// Defaults to [_DefaultScannerPlusPlatform].
  static ScannerPlusPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ScannerPlusPlatform] when
  /// they register themselves.
  static set instance(ScannerPlusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Analyze an image from a file path.
  Future<ScannerPlusCapture?> analyzeImage(String path, {ScannerPlusOptions? options}) {
    throw UnimplementedError('analyzeImage() has not been implemented.');
  }

  /// Analyzes raw bytes for barcodes.
  Future<ScannerPlusCapture?> analyzeBytes(
    Uint8List bytes, {
    required int width,
    required int height,
    required String format,
    ScannerPlusOptions? options,
  }) {
    throw UnimplementedError('analyzeBytes() has not been implemented.');
  }

  /// Gets the available cameras on the device.
  Future<List<ScannerPlusCamera>> getAvailableCameras() {
    throw UnimplementedError('getAvailableCameras() has not been implemented.');
  }

  /// Starts a live scan stream from a camera.
  ScannerPlusCameraStream startScan(ScannerPlusCamera camera, {ScannerPlusOptions? options}) {
    throw UnimplementedError('startScan() has not been implemented.');
  }

  /// Builds a platform-specific preview widget.
  Widget buildPreview(void Function(ScannerPlusCapture) onCapture) {
    return const SizedBox.shrink();
  }
}

class ScannerPlusCameraStream {
  final Stream<ScannerPlusCapture> barcodes;
  final Stream<ScannerPlusFrame> frames;

  ScannerPlusCameraStream({required this.barcodes, required this.frames});
}

class ScannerPlusFrame {
  final Uint8List bytes;
  final int width;
  final int height;

  ScannerPlusFrame({required this.bytes, required this.width, required this.height});
}

class ScannerPlusCamera {
  final String id;
  final String name;

  ScannerPlusCamera({required this.id, required this.name});
}

class _DefaultScannerPlusPlatform extends ScannerPlusPlatform {}
