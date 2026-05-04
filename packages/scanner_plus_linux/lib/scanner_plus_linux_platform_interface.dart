import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'scanner_plus_linux_method_channel.dart';

abstract class ScannerPlusLinuxPlatform extends PlatformInterface {
  /// Constructs a ScannerPlusLinuxPlatform.
  ScannerPlusLinuxPlatform() : super(token: _token);

  static final Object _token = Object();

  static ScannerPlusLinuxPlatform _instance = MethodChannelScannerPlusLinux();

  /// The default instance of [ScannerPlusLinuxPlatform] to use.
  ///
  /// Defaults to [MethodChannelScannerPlusLinux].
  static ScannerPlusLinuxPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ScannerPlusLinuxPlatform] when
  /// they register themselves.
  static set instance(ScannerPlusLinuxPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
