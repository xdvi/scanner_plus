import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'scanner_plus_linux_platform_interface.dart';

/// An implementation of [ScannerPlusLinuxPlatform] that uses method channels.
class MethodChannelScannerPlusLinux extends ScannerPlusLinuxPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('scanner_plus_linux');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
