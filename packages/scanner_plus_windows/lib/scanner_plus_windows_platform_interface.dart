import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'scanner_plus_windows_method_channel.dart';

abstract class ScannerPlusWindowsPlatform extends PlatformInterface {
  /// Constructs a ScannerPlusWindowsPlatform.
  ScannerPlusWindowsPlatform() : super(token: _token);

  static final Object _token = Object();

  static ScannerPlusWindowsPlatform _instance = MethodChannelScannerPlusWindows();

  /// The default instance of [ScannerPlusWindowsPlatform] to use.
  ///
  /// Defaults to [MethodChannelScannerPlusWindows].
  static ScannerPlusWindowsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ScannerPlusWindowsPlatform] when
  /// they register themselves.
  static set instance(ScannerPlusWindowsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
