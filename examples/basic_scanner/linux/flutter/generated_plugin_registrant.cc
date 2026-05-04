//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <scanner_plus_linux/scanner_plus_linux_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) scanner_plus_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ScannerPlusLinuxPlugin");
  scanner_plus_linux_plugin_register_with_registrar(scanner_plus_linux_registrar);
}
