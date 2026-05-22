import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'ai_dto.dart';

/// Abstraction over platform speech recognition — swap provider without UI changes.
abstract class SpeechService {
  Future<bool> initialize({AiLocale locale = AiLocale.bn});
  Future<bool> startListening();
  Future<String?> stopListening();
  Future<void> cancel();
  void dispose();

  ValueListenable<bool> get isListeningListenable;
  ValueListenable<String> get partialTranscriptListenable;
  String? get lastError;
}

class PlatformSpeechService implements SpeechService {
  PlatformSpeechService() : _speech = SpeechToText();

  final SpeechToText _speech;
  final ValueNotifier<bool> _listening = ValueNotifier(false);
  final ValueNotifier<String> _partial = ValueNotifier('');
  String? _lastError;
  String _buffer = '';
  AiLocale _locale = AiLocale.bn;

  @override
  ValueListenable<bool> get isListeningListenable => _listening;

  @override
  ValueListenable<String> get partialTranscriptListenable => _partial;

  @override
  String? get lastError => _lastError;

  @override
  Future<bool> initialize({AiLocale locale = AiLocale.bn}) async {
    _locale = locale;
    _lastError = null;
    return _speech.initialize(
      onError: (e) => _lastError = e.errorMsg,
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _listening.value = false;
        }
      },
    );
  }

  @override
  Future<bool> startListening() async {
    _lastError = null;
    _buffer = '';
    _partial.value = '';
    if (!_speech.isAvailable) {
      _lastError = 'Speech recognition unavailable';
      return false;
    }
    final started = await _speech.listen(
      localeId: _locale.speechLocaleId,
      listenMode: ListenMode.confirmation,
      onResult: (result) {
        _partial.value = result.recognizedWords;
        if (result.finalResult) {
          _buffer = result.recognizedWords;
        }
      },
    );
    _listening.value = started;
    return started;
  }

  @override
  Future<String?> stopListening() async {
    await _speech.stop();
    _listening.value = false;
    final text = _buffer.trim().isNotEmpty ? _buffer.trim() : _partial.value.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Future<void> cancel() async {
    await _speech.cancel();
    _listening.value = false;
    _buffer = '';
    _partial.value = '';
  }

  @override
  void dispose() {
    _speech.cancel();
    _listening.dispose();
    _partial.dispose();
  }
}
