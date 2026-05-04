#include "include/scanner_plus_windows/scanner_plus_windows_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "scanner_plus_windows_plugin.h"

void ScannerPlusWindowsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  scanner_plus_windows::ScannerPlusWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
