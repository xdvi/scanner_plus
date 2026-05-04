import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'scanner_plus_macos_method_channel.dart';

abstract class ScannerPlusMacosPlatform extends PlatformInterface {
  /// Constructs a ScannerPlusMacosPlatform.
  ScannerPlusMacosPlatform() : super(token: _token);

  static final Object _token = Object();

  static ScannerPlusMacosPlatform _instance = MethodChannelScannerPlusMacos();

  /// The default instance of [ScannerPlusMacosPlatform] to use.
  ///
  /// Defaults to [MethodChannelScannerPlusMacos].
  static ScannerPlusMacosPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ScannerPlusMacosPlatform] when
  /// they register themselves.
  static set instance(ScannerPlusMacosPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
