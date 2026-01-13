package ru.apps78.cotune

import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

private const val CHANNEL = "cotune_node"

class MainActivity : FlutterActivity() {

    private lateinit var bridge: CotuneBridge

    private val uiScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val bgScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        bridge = CotuneBridge.get(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    "startNode" -> {
                        android.util.Log.d("MainActivity", "startNode method called")
                        val args = call.arguments as? Map<*, *>

                        val http = (args?.get("http") as? String) ?: "127.0.0.1:7777"
                        val listen = (args?.get("listen") as? String) ?: "/ip4/0.0.0.0/tcp/0"

                        // ✅ bootstrap можно НЕ передавать — возьмётся DEFAULT_BOOTSTRAP
                        val relays =
                            (args?.get("relays") as? String)?.takeIf { it.isNotBlank() }
                                ?: CotuneBridge.DEFAULT_BOOTSTRAP

                        val basePath = (args?.get("basePath") as? String) ?: ""

                        android.util.Log.d("MainActivity", "startNode params: http=$http, listen=$listen, basePath=$basePath")

                        bgScope.launch {
                            android.util.Log.d("MainActivity", "Checking node status...")
                            // ✅ ЕСЛИ УЖЕ ЗАПУЩЕНА — НЕ СТАРТУЕМ ЕЩЁ РАЗ
                            val st = try {
                                bridge.status()
                            } catch (e: Exception) {
                                android.util.Log.w("MainActivity", "Status check failed (expected if not started): ${e.message}")
                                Result.failure(e)
                            }

                            if (st.isSuccess) {
                                val statusStr = st.getOrNull() ?: ""
                                android.util.Log.d("MainActivity", "Node status check: $statusStr")
                                // Проверяем, действительно ли нода запущена (не просто успешный ответ)
                                if (statusStr.contains("\"running\":true", ignoreCase = true)) {
                                    android.util.Log.d("MainActivity", "Node already running")
                                    uiScope.launch { result.success(statusStr) }
                                    return@launch
                                }
                            }

                            android.util.Log.d("MainActivity", "Node not running, starting...")
                            // 1️⃣ Старт ноды
                            val startRes = try {
                                bridge.startNode(http, listen, relays, basePath)
                            } catch (e: Exception) {
                                android.util.Log.e("MainActivity", "Exception calling bridge.startNode", e)
                                Result.failure(e)
                            }

                            android.util.Log.d("MainActivity", "bridge.startNode result: success=${startRes.isSuccess}, value=${startRes.getOrNull()}")
                            if (startRes.isFailure) {
                                val ex = startRes.exceptionOrNull()
                                android.util.Log.e("MainActivity", "startNode failed: ${ex?.message}", ex)
                                uiScope.launch {
                                    result.error(
                                        "start_error",
                                        ex?.message ?: "start failed",
                                        null
                                    )
                                }
                                return@launch
                            }

                            // 2️⃣ Ждём готовность через /status (poll)
                            val timeoutMs =
                                (args?.get("timeoutMs") as? Number)?.toLong() ?: 12000L

                            val deadline = System.currentTimeMillis() + timeoutMs
                            var lastErr: String? = null

                            while (System.currentTimeMillis() < deadline) {
                                val s = bridge.status()
                                if (s.isSuccess) {
                                    val payload = s.getOrNull()
                                    uiScope.launch { result.success(payload) }
                                    return@launch
                                } else {
                                    lastErr =
                                        s.exceptionOrNull()?.message ?: "status not ready"
                                }
                                delay(400)
                            }

                            // timeout
                            uiScope.launch {
                                result.error(
                                    "start_timeout",
                                    "Node started but /status not ready: $lastErr",
                                    null
                                )
                            }
                        }
                    }

                    // =========================================================
                    // ✅ STOP NODE
                    // =========================================================
                    "stopNode" -> {
                        bgScope.launch {

                            val stopRes = bridge.stopNode()
                            var stopErr: String? = null

                            if (stopRes.isFailure) {
                                stopErr = stopRes.exceptionOrNull()?.message
                            }

                            try {
                                val svcIntent =
                                    Intent(applicationContext, CotuneNodeService::class.java)
                                applicationContext.stopService(svcIntent)
                            } catch (e: Exception) {
                                stopErr = stopErr ?: e.message
                            }

                            if (stopErr == null) {
                                uiScope.launch { result.success("stopped") }
                            } else {
                                uiScope.launch {
                                    result.error("stop_error", stopErr, null)
                                }
                            }
                        }
                    }

                    // =========================================================
                    // ✅ STATUS
                    // =========================================================
                    "status" -> {
                        bgScope.launch {
                            val r = bridge.status()
                            uiScope.launch {
                                if (r.isSuccess) result.success(r.getOrNull())
                                else result.error(
                                    "status_error",
                                    r.exceptionOrNull()?.message ?: "status failed",
                                    null
                                )
                            }
                        }
                    }

                    // =========================================================
                    // ✅ PEER INFO JSON
                    // =========================================================
                    "getPeerInfoJson" -> {
                        bgScope.launch {
                            val r = bridge.getPeerInfoJson()
                            uiScope.launch {
                                if (r.isSuccess) result.success(r.getOrNull())
                                else result.error(
                                    "peerinfo_error",
                                    r.exceptionOrNull()?.message ?: "peerinfo failed",
                                    null
                                )
                            }
                        }
                    }

                    // =========================================================
                    // ✅ PEER INFO QR
                    // =========================================================
                    "getPeerInfoQrNative" -> {
                        bgScope.launch {
                            val r = bridge.getPeerInfoJson()
                            if (r.isFailure) {
                                uiScope.launch {
                                    result.error(
                                        "peerinfo_error",
                                        r.exceptionOrNull()?.message ?: "peerinfo failed",
                                        null
                                    )
                                }
                                return@launch
                            }

                            val json = r.getOrNull() ?: ""
                            val qr = bridge.renderPeerInfoQrPng(json, 1000)

                            uiScope.launch {
                                if (qr.isSuccess) result.success(qr.getOrNull())
                                else result.error(
                                    "qr_error",
                                    qr.exceptionOrNull()?.message ?: "qr failed",
                                    null
                                )
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // =========================================================
    // ✅ АВТО-ВОССТАНОВЛЕНИЕ ПОСЛЕ ВОЗВРАТА В ПРИЛОЖЕНИЕ
    // =========================================================
    override fun onResume() {
        super.onResume()

        bgScope.launch {
            val st = bridge.status()

            // ✅ Перезапускаем ТОЛЬКО если реально остановлена
            if (st.isFailure || st.getOrNull()?.contains("stopped", true) == true) {
                try {
                    // Получаем путь к директории приложения
                    val basePath = applicationContext.filesDir.absolutePath + "/cotune_data"
                    bridge.startNode(
                        CotuneBridge.DEFAULT_HTTP,
                        CotuneBridge.DEFAULT_LISTEN,
                        CotuneBridge.DEFAULT_BOOTSTRAP,
                        basePath
                    )
                } catch (_: Exception) {}
            }
        }
    }

    // =========================================================
    // ❗ НОДУ НЕ УБИВАЕМ ПРИ СВОРАЧИВАНИИ
    // =========================================================
    override fun onDestroy() {
        super.onDestroy()

        // ✅ НОДУ НЕ ТРОГАЕМ — ОНА В SERVICE
        uiScope.cancel()
        bgScope.cancel()
    }
}
