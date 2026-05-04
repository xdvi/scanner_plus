import Flutter
import UIKit
import Vision

public class ScannerPlusIosPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "scanner_plus_ios", binaryMessenger: registrar.messenger())
    let instance = ScannerPlusIosPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    // Register UIKitView
    let factory = ScannerViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "scanner_plus_view")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
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
    guard let image = UIImage(contentsOfFile: path),
          let cgImage = image.cgImage else {
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
