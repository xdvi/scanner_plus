import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scanner_plus/scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanner Plus Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late ScannerPlusController _controller;
  List<ScannerPlusBarcode> _barcodes = [];
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _controller = ScannerPlusController();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
    if (_hasPermission) {
      _initScanner();
    }
  }

  Future<void> _initScanner() async {
    await _controller.initialize();
    _controller.captures.listen((capture) {
      if (capture.barcodes.isNotEmpty) {
        HapticFeedback.lightImpact();
        setState(() {
          _barcodes = capture.barcodes;
        });
      }
    });
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Scanner Plus'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: !_hasPermission
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Camera permission required'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _checkPermissions,
                    child: const Text('Grant Permission'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // The live preview
                ScannerPlusView(controller: _controller),
                
                // Professional Overlay
                const ScannerPlusOverlay(
                  borderColor: Colors.blue,
                  cutOutSize: 280,
                ),
                
                // Overlay for detections
                if (_barcodes.isNotEmpty)
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Card(
                              color: Colors.black87,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.qr_code, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text(
                                          'Resultado del escaneo',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(color: Colors.white24),
                                    ..._barcodes.map((b) => Text(
                                      b.rawValue ?? 'N/A',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
