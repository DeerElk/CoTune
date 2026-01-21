package ru.apps78.cotune

import io.grpc.ManagedChannel
import io.grpc.ManagedChannelBuilder
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.concurrent.TimeUnit

/**
 * gRPC client for CoTune daemon IPC
 * Uses protobuf for communication instead of HTTP
 * 
 * NOTE: This implementation uses generated protobuf code from Gradle.
 * The code is automatically generated in build/generated/source/proto/main/kotlin during build.
 * 
 * Gradle protobuf plugin generates:
 * - Java classes: ru.apps78.cotune.CotuneServiceGrpc, ru.apps78.cotune.CotuneProto.*
 * - Kotlin classes: ru.apps78.cotune.CotuneServiceGrpcKt (if enabled)
 * 
 * This client uses reflection to work with generated classes until Kotlin stubs are available.
 * After build, we can directly use CotuneServiceGrpcKt.CotuneServiceCoroutineStub.
 */
class CotuneGrpcClient(private val address: String = "127.0.0.1:7777") {
    private var channel: ManagedChannel? = null
    private var stub: Any? = null

    /**
     * Connect to the gRPC server
     */
    suspend fun connect() = withContext(Dispatchers.IO) {
        if (channel == null || channel!!.isShutdown) {
            channel = ManagedChannelBuilder.forTarget(address)
                .usePlaintext() // Localhost only, no TLS needed
                .build()
            
            // Try to get the gRPC stub using reflection
            // After Gradle build, these classes will be available:
            // ru.apps78.cotune.CotuneServiceGrpc
            try {
                val stubClass = Class.forName("ru.apps78.cotune.CotuneServiceGrpc")
                val newStubMethod = stubClass.getMethod("newStub", io.grpc.Channel::class.java)
                stub = newStubMethod.invoke(null, channel)
            } catch (_: ClassNotFoundException) {
                // Generated code not available yet - will be available after build
                stub = null
            } catch (_: Exception) {
                // Other error
                stub = null
            }
        }
    }

    /**
     * Check if daemon is running
     */
    suspend fun status(): Boolean = withContext(Dispatchers.IO) {
        try {
            connect()
            if (channel == null || channel!!.isShutdown || stub == null) {
                return@withContext false
            }
            
            // Try to call status via reflection
            try {
                val statusMethod = stub!!::class.java.getMethod("status", 
                    Class.forName($$"ru.apps78.cotune.CotuneProto$StatusRequest"))
                val requestClass = Class.forName($$"ru.apps78.cotune.CotuneProto$StatusRequest")
                val request = requestClass.getMethod("getDefaultInstance").invoke(null)
                val response = statusMethod.invoke(stub, request)
                val runningMethod = response!!::class.java.getMethod("getRunning")
                return@withContext runningMethod.invoke(response) as Boolean
            } catch (_: Exception) {
                // Generated code not available or reflection failed
                // Fallback: check if channel is ready
                return@withContext !channel!!.isShutdown
            }
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Get peer information
     */
    suspend fun getPeerInfo(): Map<String, Any> = withContext(Dispatchers.IO) {
        try {
            connect()
            if (stub == null || channel!!.isShutdown) {
                return@withContext emptyMap()
            }
            
            // Try to call peerInfo via reflection
            try {
                val peerInfoMethod = stub!!::class.java.getMethod("peerInfo",
                    Class.forName($$"ru.apps78.cotune.CotuneProto$PeerInfoRequest"))
                val requestBuilderClass = Class.forName($$"ru.apps78.cotune.CotuneProto$PeerInfoRequest$Builder")
                val builder = requestBuilderClass.getMethod("newBuilder").invoke(null)
                requestBuilderClass.getMethod("setFormat", String::class.java).invoke(builder, "json")
                val request = requestBuilderClass.getMethod("build").invoke(builder)
                
                val response = peerInfoMethod.invoke(stub, request)
                val peerInfo = response!!.javaClass.getMethod("getPeerInfo").invoke(response)
                val peerId = peerInfo!!.javaClass.getMethod("getPeerId").invoke(peerInfo) as String
                val addressesMethod = peerInfo.javaClass.getMethod("getAddressesList")
                val addresses = addressesMethod.invoke(peerInfo) as? List<*> ?: emptyList<Any>()
                
                return@withContext mapOf(
                    "peer_id" to peerId,
                    "addresses" to addresses.filterIsInstance<String>()
                )
            } catch (_: Exception) {
                // Generated code not available or error
                return@withContext emptyMap()
            }
        } catch (_: Exception) {
            emptyMap()
        }
    }

    /**
     * Check if connected
     */
    fun isConnected(): Boolean {
        return channel != null && !channel!!.isShutdown && stub != null
    }

    /**
     * Disconnect from the gRPC server
     */
    suspend fun disconnect() = withContext(Dispatchers.IO) {
        channel?.shutdown()
        channel?.awaitTermination(5, TimeUnit.SECONDS)
        channel = null
        stub = null
    }
}
