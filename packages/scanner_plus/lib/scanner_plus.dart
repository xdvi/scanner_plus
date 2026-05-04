import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:scanner_plus_platform_interface/scanner_plus_platform_interface.dart';
export 'package:scanner_plus_platform_interface/scanner_plus_platform_interface.dart' show ScannerPlusCapture, ScannerPlusBarcode, ScannerPlusBarcodeFormat, ScannerPlusImageFormat, ScannerPlusOptions, ScannerPlusCamera, ScannerPlusCameraStream, ScannerPlusFrame, ScannerPlusMode;
export 'src/scanner_overlay.dart';

class ScannerPlus {
  /// Analyze an image from a file path.
  static Future<ScannerPlusCapture?> analyzeImage(String path, {ScannerPlusOptions? options}) {
    return ScannerPlusPlatform.instance.analyzeImage(path, options: options);
  }

  /// Analyzes barcodes from raw bytes.
  static Future<ScannerPlusCapture?> analyzeBytes(
    Uint8List bytes, {
    required int width,
    required int height,
    required String format,
    ScannerPlusOptions? options,
  }) {
    return ScannerPlusPlatform.instance.analyzeBytes(
      bytes,
      width: width,
      height: height,
      format: format,
      options: options,
    );
  }

  /// Gets the available cameras on the device.
  static Future<List<ScannerPlusCamera>> getAvailableCameras() {
    return ScannerPlusPlatform.instance.getAvailableCameras();
  }

  /// Starts a live scan stream from a camera.
  static ScannerPlusCameraStream startScan(ScannerPlusCamera camera, {ScannerPlusOptions? options}) {
    return ScannerPlusPlatform.instance.startScan(camera, options: options);
  }
}

class ScannerPlusController {
  ScannerPlusCamera? _camera;
  bool _isScanning = false;
  StreamSubscription? _barcodeSub;
  StreamSubscription? _frameSub;
  
  final _captureController = StreamController<ScannerPlusCapture>.broadcast();
  Stream<ScannerPlusCapture> get captures => _captureController.stream;

  final _frameController = StreamController<ScannerPlusFrame>.broadcast();
  Stream<ScannerPlusFrame> get frames => _frameController.stream;

  void addCapture(ScannerPlusCapture capture) {
    _captureController.add(capture);
  }

  Future<void> initialize() async {
    final cameras = await ScannerPlus.getAvailableCameras();
    if (cameras.isNotEmpty) {
      _camera = cameras.first;
    }
  }

  void start() {
    if (_camera == null || _isScanning) return;
    _isScanning = true;
    
    final stream = ScannerPlus.startScan(_camera!);
    _barcodeSub = stream.barcodes.listen((capture) {
      _captureController.add(capture);
    });
    _frameSub = stream.frames.listen((frame) {
      _frameController.add(frame);
    });
  }

  void stop() {
    _barcodeSub?.cancel();
    _frameSub?.cancel();
    _isScanning = false;
  }

  void dispose() {
    stop();
    _captureController.close();
    _frameController.close();
  }
}

class ScannerPlusView extends StatefulWidget {
  final ScannerPlusController controller;

  const ScannerPlusView({super.key, required this.controller});

  @override
  State<ScannerPlusView> createState() => _ScannerPlusViewState();
}

class _ScannerPlusViewState extends State<ScannerPlusView> {
  ui.Image? _image;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.controller.frames.listen((frame) {
      ui.decodeImageFromPixels(
        frame.bytes,
        frame.width,
        frame.height,
        ui.PixelFormat.rgba8888,
        (image) {
          if (mounted) {
            setState(() {
              _image?.dispose();
              _image = image;
            });
          } else {
            image.dispose();
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Try native platform preview first
    final platformPreview = ScannerPlusPlatform.instance.buildPreview(widget.controller.addCapture);
    if (platformPreview is! SizedBox) {
      return platformPreview;
    }

    if (_image == null) {
      return Container(
        color: const ui.Color(0xFF000000),
        child: const Center(
          child: Text(
            'Waiting for camera...',
            style: TextStyle(color: ui.Color(0xFFFFFFFF)),
          ),
        ),
      );
    }

    return RawImage(
      image: _image,
      fit: BoxFit.cover,
    );
  }
}
