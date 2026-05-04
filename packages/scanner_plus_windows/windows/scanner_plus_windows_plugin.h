#ifndef FLUTTER_PLUGIN_SCANNER_PLUS_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_SCANNER_PLUS_WINDOWS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace scanner_plus_windows {

class ScannerPlusWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  ScannerPlusWindowsPlugin();

  virtual ~ScannerPlusWindowsPlugin();

  // Disallow copy and assign.
  ScannerPlusWindowsPlugin(const ScannerPlusWindowsPlugin&) = delete;
  ScannerPlusWindowsPlugin& operator=(const ScannerPlusWindowsPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace scanner_plus_windows

#endif  // FLUTTER_PLUGIN_SCANNER_PLUS_WINDOWS_PLUGIN_H_
