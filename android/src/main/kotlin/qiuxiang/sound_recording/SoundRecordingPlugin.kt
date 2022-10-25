package qiuxiang.sound_recording

import io.flutter.embedding.engine.plugins.FlutterPlugin

class SoundRecordingPlugin : FlutterPlugin {
  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    Pigeon.SoundRecordingApi.setup(binding.binaryMessenger, SoundRecordingApi(binding.binaryMessenger))
  }
}
