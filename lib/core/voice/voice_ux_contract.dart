/// UX contract — accessibility-first voice UI.
enum VoiceWaveformState {
  idle,
  listening,
  processing,
  speaking,
  error,
}

enum VoiceInputMode {
  tapToTalk,
  pushToHold,
}

abstract class VoiceUxContract {
  static const largeButtonMinSize = 72.0;
  static const replayEnabled = true;
  static const transcriptVisible = true;

  static const labelsBn = {
    'tapToTalk': 'বলতে ট্যাপ করুন',
    'pushToHold': 'ধরে রাখুন',
    'replay': 'আবার শুনুন',
    'retry': 'আবার বলুন',
    'help': 'সাহায্য',
  };
}
