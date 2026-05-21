/// Microphone + codec abstraction — no background recording.
abstract class VoiceAudioContract {
  static const maxRecordingSeconds = 30;

  Future<bool> requestPermission();

  Future<void> startRecording({required bool pushToHold});

  Future<void> stopRecording();

  Future<List<int>?> readCompressedChunk({int bitrateKbps = 16});

  void dispose();
}

/// Local offline upload queue for weak networks.
abstract class VoiceQueueContract {
  static const boxName = 'voice_upload_queue_v1';

  Future<void> enqueue(Map<String, dynamic> payload);

  Future<List<Map<String, dynamic>>> pending();

  Future<void> markUploaded(String id);
}
