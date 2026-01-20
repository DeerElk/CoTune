package ru.apps78.cotune

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.File
import java.util.concurrent.atomic.AtomicReference

class CotuneNodePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val nodeProcess = AtomicReference<Process?>(null)
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "cotune_node")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopNode()
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startNode" -> {
                scope.launch {
                    try {
                        startNode(call, result)
                    } catch (e: Exception) {
                        result.error("START_ERROR", e.message, null)
                    }
                }
            }
            "stopNode" -> {
                scope.launch {
                    try {
                        stopNode()
                        result.success("stopped")
                    } catch (e: Exception) {
                        result.error("STOP_ERROR", e.message, null)
                    }
                }
            }
            "getPeerInfoQrNative" -> {
                scope.launch {
                    try {
                        val qrBytes = getPeerInfoQr(call)
                        result.success(qrBytes)
                    } catch (e: Exception) {
                        result.error("QR_ERROR", e.message, null)
                    }
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private suspend fun startNode(
        call: MethodCall,
        result: MethodChannel.Result
    ) = withContext(Dispatchers.IO) {
        // Use protobuf IPC address (default: localhost TCP)
        val protoAddr = call.argument<String>("proto") ?: call.argument<String>("http") ?: "127.0.0.1:7777"
        val listen = call.argument<String>("listen") ?: "/ip4/0.0.0.0/tcp/0"
        val relays = call.argument<String>("relays") ?: ""
        val basePath = call.argument<String>("basePath")

        // Stop existing process if any
        stopNode()

        // Get data directory
        val dataDir = basePath ?: context.filesDir.absolutePath
        File(dataDir).mkdirs()

        // Find Go daemon binary
        val goBinary = findGoBinary()
        if (goBinary == null) {
            result.error("NO_BINARY", "Go daemon binary (cotune-daemon) not found in native library directory", null)
            return@withContext
        }

        // Build command to execute Go daemon
        val command = mutableListOf<String>()
        command.add(goBinary)
        command.add("-proto")
        command.add(protoAddr)
        command.add("-listen")
        command.add(listen)
        command.add("-data")
        command.add(dataDir)
        if (relays.isNotEmpty()) {
            // Handle relays if needed
        }

        Log.d(TAG, "Starting daemon: ${command.joinToString(" ")}")

        try {
            val process = ProcessBuilder(command)
                .directory(File(dataDir))
                .redirectErrorStream(true)
                .start()

            nodeProcess.set(process)

            // Wait a bit for startup
            delay(2000)

            // Check if process is still running
            if (!process.isAlive) {
                val exitCode = process.exitValue()
                result.error("PROCESS_DIED", "Process exited with code $exitCode", null)
                return@withContext
            }

            // Check Protobuf/gRPC IPC
            try {
                val client = CotuneGrpcClient(protoAddr)
                client.connect()
                delay(1000) // Give daemon time to start gRPC server
                val isRunning = client.status()
                if (isRunning && process.isAlive) {
                    result.success("started")
                } else if (!process.isAlive) {
                    result.error("API_ERROR", "Daemon process died", null)
                } else {
                    Log.w(TAG, "gRPC not ready yet, but daemon started")
                    result.success("started")
                }
                client.disconnect()
            } catch (e: Exception) {
                Log.w(TAG, "Protobuf IPC not ready yet, but daemon started", e)
                // Fallback: just check if process is alive
                if (process.isAlive) {
                    result.success("started")
                } else {
                    result.error("API_ERROR", "Daemon process died", null)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start daemon", e)
            result.error("START_FAILED", e.message, null)
        }
    }

    private suspend fun stopNode() = withContext(Dispatchers.IO) {
        val process = nodeProcess.getAndSet(null)
        process?.let {
            try {
                it.destroy()
                if (!it.waitFor(5, java.util.concurrent.TimeUnit.SECONDS)) {
                    it.destroyForcibly()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping process", e)
            }
        }
    }

    private suspend fun getPeerInfoQr(call: MethodCall): ByteArray = withContext(Dispatchers.Default) {
        // Get peer info from call or fetch from HTTP API
        val peerInfoJson = call.argument<String>("peerInfo")
            ?: throw IllegalArgumentException("peerInfo required")

        // Generate QR code
        val writer = QRCodeWriter()
        val hints = hashMapOf<EncodeHintType, Any>().apply {
            put(EncodeHintType.CHARACTER_SET, "UTF-8")
            put(EncodeHintType.MARGIN, 1)
        }

        val bitMatrix = writer.encode(peerInfoJson, BarcodeFormat.QR_CODE, 800, 800, hints)

        // Convert to bitmap
        val width = bitMatrix.width
        val height = bitMatrix.height
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)

        for (x in 0 until width) {
            for (y in 0 until height) {
                bitmap.setPixel(x, y, if (bitMatrix[x, y]) 0xFF000000.toInt() else 0xFFFFFFFF.toInt())
            }
        }

        // Convert to PNG bytes
        val stream = java.io.ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        stream.toByteArray()
    }

    private fun findGoBinary(): String? {
        // Find Go daemon binary in native library directory
        // The daemon is built as an executable binary, not a shared library
        val nativeLibDir = context.applicationInfo.nativeLibraryDir
        val binaryPath = File(nativeLibDir, "cotune-daemon")
        
        return if (binaryPath.exists() && binaryPath.canExecute()) {
            binaryPath.absolutePath
        } else {
            null
        }
    }

    companion object {
        private const val TAG = "CotuneNodePlugin"
    }
}
