import FlutterMacOS
import Foundation
import Vision
import AppKit

public class ScannerPlusMacosPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "scanner_plus_macos", binaryMessenger: registrar.messenger)
    let instance = ScannerPlusMacosPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    // macOS also supports PlatformViews (NSView)
    // However, they are often registered differently or we can use the same pattern if using FlutterMacOS
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "analyzeImage":
      guard let args = call.arguments as? [String: Any],
            let path = args["path"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Path is null", details: nil))
        return
      }
      analyzeImage(path: path, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func analyzeImage(path: String, result: @escaping FlutterResult) {
    guard let image = NSImage(contentsOfFile: path),
          let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      result(FlutterError(code: "IMAGE_LOAD_FAILED", message: "Could not load image", details: nil))
      return
    }

    let request = VNDetectBarcodesRequest { request, error in
      if let error = error {
        result(FlutterError(code: "SCAN_FAILED", message: error.localizedDescription, details: nil))
        return
      }

      let results = (request.results as? [VNBarcodeObservation])?.map { barcode in
        return [
          "rawValue": barcode.payloadStringValue,
          "format": String(describing: barcode.symbology)
        ]
      } ?? []
      result(results)
    }

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try? handler.perform([request])
  }
}
