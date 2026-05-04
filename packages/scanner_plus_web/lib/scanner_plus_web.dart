import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:scanner_plus_platform_interface/scanner_plus_platform_interface.dart';
import 'package:scanner_plus_rust_core/scanner_plus_rust_core.dart' as api;
import 'package:web/web.dart' as web;

@JS()
extension type BarcodeDetectorOptions._(JSObject _) implements JSObject {
  external BarcodeDetectorOptions({JSArray<JSString> formats});
}

@JS()
extension type BarcodeResult._(JSObject _) implements JSObject {
  external JSString get rawValue;
  external JSString get format;
}

@JS('BarcodeDetector')
extension type BarcodeDetector._(JSObject _) implements JSObject {
  external BarcodeDetector(BarcodeDetectorOptions options);
  external JSPromise<JSArray<BarcodeResult>> detect(web.HTMLVideoElement video);
}

class ScannerPlusWeb extends ScannerPlusPlatform {
  static void registerWith(Registrar registrar) {
    ScannerPlusPlatform.instance = ScannerPlusWeb();
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

  ScannerPlusCapture? _mapResults(List<api.BarcodeResult> results) {
    if (results.isEmpty) return null;
    return ScannerPlusCapture(
      timestamp: DateTime.now(),
      barcodes: results.map((r) => ScannerPlusBarcode(
        rawValue: r.text,
        format: _mapFormat(r.format),
        rawBytes: r.bytes,
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

  @override
  Widget buildPreview(void Function(ScannerPlusCapture) onCapture) {
    final String viewId = 'scanner-plus-video-${DateTime.now().millisecondsSinceEpoch}';
    
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
      final video = web.document.createElement('video') as web.HTMLVideoElement;
      video.autoplay = true;
      video.muted = true;
      video.setAttribute('playsinline', 'true');
      video.style.width = '100%';
      video.style.height = '100%';
      video.style.objectFit = 'cover';

      () async {
        try {
          final stream = await web.window.navigator.mediaDevices
              .getUserMedia(web.MediaStreamConstraints(video: true.toJS))
              .toDart;
          video.srcObject = stream;
          _startDecoding(video, onCapture);
        } catch (e) {
          debugPrint('ScannerPlusWeb: Failed to start camera: $e');
        }
      }();

      return video;
    });

    return HtmlElementView(viewType: viewId);
  }

  void _startDecoding(web.HTMLVideoElement video, void Function(ScannerPlusCapture) onCapture) async {
    // Check if BarcodeDetector is supported
    final bool hasNativeSupport = (web.window as JSObject).hasProperty('BarcodeDetector'.toJS).toDart;

    if (hasNativeSupport) {
      final formats = ['qr_code', 'ean_13', 'code_128', 'pdf417'];
      final detector = BarcodeDetector(BarcodeDetectorOptions(
        formats: formats.map((e) => e.toJS).toList().toJS,
      ));

      Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        if (video.paused || video.ended) {
          timer.cancel();
          return;
        }
        
        try {
          final results = await detector.detect(video).toDart;
          if (results.toDart.isNotEmpty) {
            onCapture(ScannerPlusCapture(
              timestamp: DateTime.now(),
              barcodes: results.toDart.map((b) => ScannerPlusBarcode(
                rawValue: b.rawValue.toDart,
                format: _mapWebFormat(b.format.toDart),
              )).toList(),
            ));
          }
        } catch (e) {
          // Detection error
        }
      });
    } else {
      _startRustWasmDecoding(video, onCapture);
    }
  }

  void _startRustWasmDecoding(web.HTMLVideoElement video, void Function(ScannerPlusCapture) onCapture) {
    // For WASM fallback, we capture frames from the video using a canvas
    // and send them to the Rust core for analysis.
    final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
    final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;

    Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      if (video.paused || video.ended) {
        timer.cancel();
        return;
      }

      try {
        // Match canvas size to video
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        
        // Draw current frame
        context.drawImage(video, 0, 0);
        
        // Get pixel data
        final imageData = context.getImageData(0, 0, canvas.width, canvas.height);
        final clampedList = imageData.data.toDart;
        final bytes = clampedList.buffer.asUint8List();

        // Analyze via Rust WASM
        // Note: api.RustLib.init() should have been called in registerWith or here
        final capture = await analyzeBytes(
          bytes,
          width: canvas.width,
          height: canvas.height,
          format: 'RGBA', // Standard canvas format
        );

        if (capture != null && capture.barcodes.isNotEmpty) {
          onCapture(capture);
        }
      } catch (e) {
        // Silent error
      }
    });
  }

  ScannerPlusBarcodeFormat _mapWebFormat(String format) {
    switch (format.toLowerCase()) {
      case 'qr_code': return ScannerPlusBarcodeFormat.qrCode;
      case 'ean_13': return ScannerPlusBarcodeFormat.ean13;
      case 'code_128': return ScannerPlusBarcodeFormat.code128;
      default: return ScannerPlusBarcodeFormat.unknown;
    }
  }

  @override
  Future<List<ScannerPlusCamera>> getAvailableCameras() async {
    final devices = await web.window.navigator.mediaDevices.enumerateDevices().toDart;
    return devices.toDart
        .where((d) => d.kind == 'videoinput')
        .map((d) => ScannerPlusCamera(id: d.deviceId, name: d.label))
        .toList();
  }
}
