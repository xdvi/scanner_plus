package com.scanner_plus.scanner_plus_android

import android.content.Context
import androidx.annotation.NonNull
import androidx.lifecycle.LifecycleOwner
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** ScannerPlusAndroidPlugin */
class ScannerPlusAndroidPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private var lifecycleOwner: LifecycleOwner? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "scanner_plus_android")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
    
    flutterPluginBinding.platformViewRegistry.registerViewFactory(
      "scanner_plus_view",
      ScannerViewFactory(flutterPluginBinding.binaryMessenger) { lifecycleOwner }
    )
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "analyzeImage" -> {
        val path = call.argument<String>("path")
        if (path != null) {
          analyzeImageFile(path, result)
        } else {
          result.error("INVALID_ARGUMENT", "Path is null", null)
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun analyzeImageFile(path: String, result: Result) {
    try {
      val image = InputImage.fromFilePath(context, android.net.Uri.parse("file://$path"))
      val scanner = BarcodeScanning.getClient()
      
      scanner.process(image)
        .addOnSuccessListener { barcodes ->
          val results = barcodes.map { barcode ->
            mapOf(
              "rawValue" to barcode.rawValue,
              "format" to barcode.format.toString()
            )
          }
          result.success(results)
        }
        .addOnFailureListener { e ->
          result.error("SCAN_FAILED", e.message, null)
        }
    } catch (e: Exception) {
      result.error("IMAGE_LOAD_FAILED", e.message, null)
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    lifecycleOwner = binding.activity as? LifecycleOwner
  }

  override fun onDetachedFromActivityForConfigChanges() {
    lifecycleOwner = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    lifecycleOwner = binding.activity as? LifecycleOwner
  }

  override fun onDetachedFromActivity() {
    lifecycleOwner = null
  }
}
