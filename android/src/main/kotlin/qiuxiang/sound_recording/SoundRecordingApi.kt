package qiuxiang.sound_recording

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import androidx.annotation.UiThread
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

  override fun init(bufferSize: Long, sampleRate: Long, result: Pigeon.Result<Void>) {
    if (recording || recordingThread?.isAlive == true) {
      return
    }

    if (initialized) {
      audioRecord?.stop()
      audioRecord?.release()
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
      recordingThread = thread(start = false) { readData() }
      result.success(null)
    } else {
      result.error(null)
    }
  }

  @UiThread
  private fun readData() {
    val buffer = ShortArray(bufferSize)
    while (recording) {
      audioRecord?.read(buffer, 0, bufferSize)
      handler.post {
        recordingHandler.read(buffer.map { i -> i.toLong() }.toMutableList()) {}
      }
    }
  }

  override fun start(result: Pigeon.Result<Void>) {
    if (initialized && recordingThread != null) {
      audioRecord?.startRecording()
      recordingThread?.start()
    }
    result.success(null)
  }

  override fun stop(result: Pigeon.Result<Void>) {
    if (initialized) {
      audioRecord?.stop()
      audioRecord?.release()
      audioRecord = null
    }
    result.success(null)
  }
}