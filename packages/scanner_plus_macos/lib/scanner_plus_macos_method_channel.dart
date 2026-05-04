import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'scanner_plus_macos_platform_interface.dart';

/// An implementation of [ScannerPlusMacosPlatform] that uses method channels.
class MethodChannelScannerPlusMacos extends ScannerPlusMacosPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('scanner_plus_macos');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
