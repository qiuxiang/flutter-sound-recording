package qiuxiang.sound_recording

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import qiuxiang.sound_recording.Pigeon.SoundRecordingHandler
import kotlin.concurrent.thread

class SoundRecordingApi(messenger: BinaryMessenger) : Pigeon.SoundRecordingApi {
  private var bufferSize: Int = 0
  private var audioRecord: AudioRecord? = null
  private var recordingThread: Thread? = null
  private var recordingHandler = SoundRecordingHandler(messenger)
  private val handler = Handler(Looper.getMainLooper())

  private val initialized: Boolean
    get() = audioRecord?.state == AudioRecord.STATE_INITIALIZED

  private val recording: Boolean
    get() = audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING

  private fun readData() {
    val buffer = ShortArray(bufferSize)
    while (recording) {
      audioRecord?.read(buffer, 0, bufferSize)
      handler.post {
        recordingHandler.read(buffer.map { i -> i.toLong() }.toMutableList()) {}
      }
    }
    stop()
  }

  override fun start(bufferSize: Long, sampleRate: Long, result: Pigeon.Result<Void>) {
    if (recording) {
      return result.success(null)
    }

    this.bufferSize = bufferSize.toInt()
    audioRecord = AudioRecord(
      MediaRecorder.AudioSource.MIC,
      sampleRate.toInt(),
      AudioFormat.CHANNEL_IN_MONO,
      AudioFormat.ENCODING_PCM_16BIT,
      this.bufferSize * 2
    )
    if (initialized) {
      audioRecord?.startRecording()
      recordingThread = thread { readData() }
      result.success(null)
    } else {
      result.error(null)
    }
  }

  override fun stop(result: Pigeon.Result<Void>) {
    stop()
    result.success(null)
  }

  private fun stop() {
    if (initialized) {
      if (recording) {
        audioRecord?.stop()
      }
      audioRecord?.release()
      audioRecord = null
    }
  }
}
