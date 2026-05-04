import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'scanner_plus_windows_platform_interface.dart';

/// An implementation of [ScannerPlusWindowsPlatform] that uses method channels.
class MethodChannelScannerPlusWindows extends ScannerPlusWindowsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('scanner_plus_windows');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
