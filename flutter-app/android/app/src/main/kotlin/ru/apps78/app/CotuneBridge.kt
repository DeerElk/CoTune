package ru.apps78.cotune

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.journeyapps.barcodescanner.BarcodeEncoder
import kotlinx.coroutines.*
import cotune.Cotune
import java.io.ByteArrayOutputStream
import kotlin.coroutines.CoroutineContext

class CotuneBridge private constructor(private val ctx: Context) : CoroutineScope {

    companion object {
        @Volatile
        private var instance: CotuneBridge? = null

        // ❗ ОБЯЗАТЕЛЬНО ЗАМЕНИ НА РЕАЛЬНЫЙ PEER ID
        const val DEFAULT_BOOTSTRAP =
            "/ip4/84.201.172.91/tcp/4001/p2p/12D3KooWPg8PavCBcMzooYYHbnoEN5YttQng3YGABvVwkbM5gvPb"
        const val DEFAULT_HTTP = "127.0.0.1:7777"
        const val DEFAULT_LISTEN = "/ip4/0.0.0.0/tcp/0"

        fun get(ctx: Context): CotuneBridge {
            return instance ?: synchronized(this) {
                instance ?: CotuneBridge(ctx.applicationContext).also { instance = it }
            }
        }
    }

    private val job = SupervisorJob()
    override val coroutineContext: CoroutineContext
        get() = Dispatchers.IO + job

    suspend fun startNode(
        httpHostPort: String = "127.0.0.1:7777",
        listen: String = "/ip4/0.0.0.0/tcp/0",
        relaysCSV: String = DEFAULT_BOOTSTRAP,
        basePath: String = ""
    ): Result<String> = withContext(Dispatchers.IO) {
        try {
            android.util.Log.d("CotuneBridge", "startNode called: http=$httpHostPort, listen=$listen, basePath=$basePath")
            System.out.println("CotuneBridge: startNode called")
            val intent = Intent(ctx, CotuneNodeService::class.java).apply {
                putExtra("http", httpHostPort)
                putExtra("listen", listen)
                putExtra("relays", relaysCSV)
                putExtra("basePath", basePath)
            }

            android.util.Log.d("CotuneBridge", "Starting foreground service...")
            System.out.println("CotuneBridge: Starting foreground service...")
            try {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    ctx.startForegroundService(intent)
                    System.out.println("CotuneBridge: startForegroundService called")
                } else {
                    ctx.startService(intent)
                    System.out.println("CotuneBridge: startService called (old API)")
                }
                android.util.Log.d("CotuneBridge", "Foreground service started successfully")
                System.out.println("CotuneBridge: Service started successfully")
            } catch (e: android.content.ActivityNotFoundException) {
                android.util.Log.e("CotuneBridge", "ActivityNotFoundException: Service not found", e)
                throw e
            } catch (e: IllegalStateException) {
                android.util.Log.e("CotuneBridge", "IllegalStateException: ${e.message}", e)
                // Попробуем обычный startService как fallback
                try {
                    ctx.startService(intent)
                    android.util.Log.d("CotuneBridge", "Used startService as fallback")
                } catch (e2: Exception) {
                    android.util.Log.e("CotuneBridge", "Fallback startService also failed", e2)
                    throw e
                }
            } catch (e: Exception) {
                android.util.Log.e("CotuneBridge", "Unexpected exception starting service", e)
                throw e
            }

            return@withContext Result.success("service_started")
        } catch (e: Exception) {
            android.util.Log.e("CotuneBridge", "Failed to start service", e)
            return@withContext Result.failure(e)
        }
    }

    suspend fun stopNode(): Result<String> = withContext(Dispatchers.IO) {
        try {
            val out = Cotune.stopNode()  // <-- исправлено
            return@withContext Result.success(out)
        } catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    suspend fun status(): Result<String> = withContext(Dispatchers.IO) {
        try {
            val out = Cotune.status()  // <-- исправлено
            return@withContext Result.success(out)
        } catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    suspend fun getPeerInfoJson(): Result<String> = withContext(Dispatchers.IO) {
        try {
            val out = Cotune.getPeerInfoJson()  // <-- исправлено
            return@withContext Result.success(out)
        } catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    /**
     * ✅ Генерация PNG QR-кода
     */
    suspend fun renderPeerInfoQrPng(
        peerInfoJson: String,
        size: Int = 800
    ): Result<ByteArray> = withContext(Dispatchers.Default) {
        try {
            val hints = mapOf<EncodeHintType, Any>(
                EncodeHintType.CHARACTER_SET to "UTF-8"
            )
            val encoder = BarcodeEncoder()
            val bitmap: Bitmap =
                encoder.encodeBitmap(peerInfoJson, BarcodeFormat.QR_CODE, size, size, hints)

            val baos = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos)
            val bytes = baos.toByteArray()
            baos.close()

            return@withContext Result.success(bytes)
        } catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    fun shutdown() {
        job.cancel()
    }
}
