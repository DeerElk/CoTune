package ru.apps78.cotune

import io.flutter.embedding.engine.plugins.FlutterPlugin

class CotunePluginRegistrant {
    companion object {
        fun registerWith(registry: FlutterPlugin.FlutterPluginRegistry) {
            val plugin = CotuneNodePlugin()
            registry.registrarFor("ru.apps78.cotune.CotuneNodePlugin")?.let { registrar ->
                plugin.onAttachedToEngine(
                    object : FlutterPlugin.FlutterPluginBinding {
                        override fun getApplicationContext(): android.content.Context {
                            return registrar.context()
                        }

                        override fun getBinaryMessenger(): io.flutter.plugin.common.BinaryMessenger {
                            return registrar.messenger()
                        }

                        override fun getPlatformViewRegistry(): io.flutter.plugin.platform.PlatformViewRegistry {
                            return registrar.platformViewRegistry()
                        }

                        override fun getTextureRegistry(): io.flutter.view.TextureRegistry {
                            return registrar.textureRegistry()
                        }
                    }
                )
            }
        }
    }
}
