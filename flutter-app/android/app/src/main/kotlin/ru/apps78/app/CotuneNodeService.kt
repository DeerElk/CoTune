package ru.apps78.cotune

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import cotune.Cotune

class CotuneNodeService : Service() {

    init {
        android.util.Log.i("CotuneNodeService", "!!! CotuneNodeService class initialized !!!")
        System.out.println("CotuneNodeService: class initialized")
    }

    override fun onCreate() {
        super.onCreate()
        android.util.Log.i("CotuneNodeService", "=== onCreate called ===")
        System.out.println("CotuneNodeService: onCreate called")
        android.util.Log.d("CotuneNodeService", "onCreate: creating notification channel")
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    "cotune",
                    "Cotune Node",
                    NotificationManager.IMPORTANCE_LOW
                )
                val manager = getSystemService(NotificationManager::class.java)
                manager.createNotificationChannel(channel)
                android.util.Log.d("CotuneNodeService", "Notification channel created")
            }
        } catch (e: Exception) {
            android.util.Log.e("CotuneNodeService", "Error in onCreate", e)
        }
        android.util.Log.i("CotuneNodeService", "=== onCreate completed ===")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        android.util.Log.i("CotuneNodeService", "=== onStartCommand called ===")
        System.out.println("CotuneNodeService: onStartCommand called")
        android.util.Log.d("CotuneNodeService", "onStartCommand: flags=$flags, startId=$startId")

        val notification: Notification =
            NotificationCompat.Builder(this, "cotune")
                .setContentTitle("Cotune")
                .setContentText("P2P node is running")
                .setSmallIcon(R.mipmap.ic_launcher)
                .build()

        startForeground(1, notification)
        android.util.Log.d("CotuneNodeService", "Foreground notification started")

        val http = intent?.getStringExtra("http") ?: "127.0.0.1:7777"
        val listen = intent?.getStringExtra("listen") ?: "/ip4/0.0.0.0/tcp/0"
        val relays = intent?.getStringExtra("relays")
            ?: CotuneBridge.DEFAULT_BOOTSTRAP
        // Если basePath не передан, используем директорию приложения
        val basePath = intent?.getStringExtra("basePath")
            ?: (filesDir.absolutePath + "/cotune_data")

        android.util.Log.d("CotuneNodeService", "Parameters: http=$http, listen=$listen, basePath=$basePath")

        Thread {
            try {
                android.util.Log.d("CotuneNodeService", "Thread started, calling Cotune.startNode...")
                System.out.println("CotuneNodeService: Thread started, calling Cotune.startNode")
                android.util.Log.d("CotuneNodeService", "Calling: http=$http, listen=$listen, relays=$relays, basePath=$basePath")
                System.out.println("CotuneNodeService: http=$http, listen=$listen, basePath=$basePath")

                val result = try {
                    Cotune.startNode(http, listen, relays, basePath)
                } catch (e: Throwable) {
                    android.util.Log.e("CotuneNodeService", "Cotune.startNode threw exception", e)
                    android.util.Log.e("CotuneNodeService", "Exception type: ${e.javaClass.name}")
                    android.util.Log.e("CotuneNodeService", "Exception message: ${e.message}")
                    e.printStackTrace()
                    return@Thread
                }

                android.util.Log.d("CotuneNodeService", "Cotune.startNode returned: '$result'")

                if (result == "ok" || result == "already") {
                    android.util.Log.i("CotuneNodeService", "Node started successfully: $result")
                    // Даем время на запуск HTTP сервера (увеличено до 3 секунд)
                    Thread.sleep(3000)
                    // Проверяем статус несколько раз
                    for (i in 1..5) {
                        try {
                            val status = Cotune.status()
                            android.util.Log.d("CotuneNodeService", "Node status check $i: $status")
                            if (status.contains("\"running\":true", ignoreCase = true)) {
                                android.util.Log.i("CotuneNodeService", "HTTP server is ready!")
                                break
                            }
                        } catch (e: Exception) {
                            android.util.Log.w("CotuneNodeService", "Status check $i failed: ${e.message}")
                        }
                        if (i < 5) Thread.sleep(1000)
                    }
                } else {
                    android.util.Log.e("CotuneNodeService", "Node start failed, returned: '$result'")
                }
            } catch (e: Exception) {
                android.util.Log.e("CotuneNodeService", "Unexpected exception in startNode thread", e)
                e.printStackTrace()
            }
        }.start()

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
