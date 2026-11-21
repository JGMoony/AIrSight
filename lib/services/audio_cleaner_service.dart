import '../features/glossary/glossary_word.dart';

/// Servicio de sanitización acústica y preparación de oraciones para TTS (WCAG 2.2 AA).
/// Transforma marcadores visuales "_____" o palabras "blank" en pausas auditivas ("... ")
/// e implementa utilidades de segmentación para silencios programados en ejercicios.
class AudioCleanerService {
  AudioCleanerService._();

  /// Limpia y sanitiza una oración para que el motor de síntesis de voz (TTS)
  /// no vocalice "guiones bajos", "underscore" o "blank" literalmente.
  static String cleanForTts(String text) {
    return text
        .replaceAll(RegExp(r'_{2,}'), '... ')
        .replaceAll(RegExp(r'\bblank\b', caseSensitive: false), '... ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Genera una oración contextual en inglés reemplazando la palabra objetivo por "_____".
  /// Si la palabra no está presente en [exampleEn], utiliza un fallback seguro de nivel A1.
  static String generateSentenceWithBlank(GlossaryWord word) {
    final en = word.exampleEn;
    final pattern = RegExp(RegExp.escape(word.wordEn), caseSensitive: false);
    if (pattern.hasMatch(en)) {
      return en.replaceFirst(pattern, '_____');
    }
    return 'The _____ is here.';
  }

  /// Divide la oración con espacio en blanco en dos partes (antes y después de "_____")
  /// para permitir la inserción de una pausa de silencio programada en el motor TTS.
  static List<String> splitSentenceAroundBlank(String sentenceWithBlank) {
    return sentenceWithBlank
        .split('_____')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }
}
