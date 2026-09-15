import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceSearchService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  bool get isListening => _speech.isListening;

  /// Inicializa el motor de reconocimiento de voz y solicita permisos de micrófono
  Future<bool> initialize({
    Function(String error)? onError,
    Function(String status)? onStatus,
  }) async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (val) => onError?.call(val.errorMsg),
        onStatus: (val) => onStatus?.call(val),
      );
      return _isInitialized;
    } catch (e) {
      onError?.call(e.toString());
      return false;
    }
  }

  /// Inicia la escucha por micrófono
  Future<bool> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(String error)? onError,
  }) async {
    if (!_isInitialized) {
      final ready = await initialize(onError: onError);
      if (!ready) {
        onError?.call('No se pudo inicializar el micrófono.');
        return false;
      }
    }

    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
        ),
      );
      return true;
    } catch (e) {
      onError?.call(e.toString());
      return false;
    }
  }

  /// Detiene la escucha
  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }
}
