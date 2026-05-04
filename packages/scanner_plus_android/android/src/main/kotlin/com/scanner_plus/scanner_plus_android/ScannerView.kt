package com.scanner_plus.scanner_plus_android

import android.content.Context
import android.view.View
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class ScannerViewFactory(
    private val messenger: BinaryMessenger,
    private val lifecycleProvider: () -> LifecycleOwner?
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String?, Any?>?
        return ScannerView(context, messenger, viewId, creationParams, lifecycleProvider)
    }
}

class ScannerView(
    private val context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    params: Map<String?, Any?>?,
    private val lifecycleProvider: () -> LifecycleOwner?
) : PlatformView {
    private val previewView: PreviewView = PreviewView(context)
    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val barcodeChannel = EventChannel(messenger, "scanner_plus_android/barcodes/$viewId")
    private var eventSink: EventChannel.EventSink? = null

    init {
        barcodeChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
        startCamera()
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)

        cameraProviderFuture.addListener({
            val cameraProvider: ProcessCameraProvider = cameraProviderFuture.get()

            val preview = Preview.Builder().build().also {
                it.setSurfaceProvider(previewView.surfaceProvider)
            }

            val barcodeScanner = BarcodeScanning.getClient()
            val imageAnalysis = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()
                .also {
                    it.setAnalyzer(cameraExecutor) { imageProxy ->
                        val mediaImage = imageProxy.image
                        if (mediaImage != null) {
                            val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
                            barcodeScanner.process(image)
                                .addOnSuccessListener { barcodes ->
                                    if (barcodes.isNotEmpty()) {
                                        val results = barcodes.map { barcode ->
                                            mapOf(
                                                "rawValue" to barcode.rawValue,
                                                "format" to barcode.format.toString()
                                            )
                                        }
                                        eventSink?.success(results)
                                    }
                                }
                                .addOnCompleteListener {
                                    imageProxy.close()
                                }
                        } else {
                            imageProxy.close()
                        }
                    }
                }

            val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

            try {
                cameraProvider.unbindAll()
                lifecycleProvider()?.let { owner ->
                    cameraProvider.bindToLifecycle(owner, cameraSelector, preview, imageAnalysis)
                }
            } catch (exc: Exception) {
                // Handle errors
            }
        }, ContextCompat.getMainExecutor(context))
    }

    override fun getView(): View {
        return previewView
    }

    override fun dispose() {
        cameraExecutor.shutdown()
    }
}
