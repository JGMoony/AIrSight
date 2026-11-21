import 'dart:math';

/// Servicio pedagógico accesible para retroalimentación motivacional aleatoria (MCER A1).
/// Selecciona de forma no lineal y sin repetición consecutiva frases de aliento bilingües
/// para visualización en pantalla y síntesis de voz (TTS) durante las prácticas guiadas.
class EncouragementService {
  EncouragementService._();

  static final Random _random = Random();
  static int _lastIndex = -1;

  static const List<String> _encouragements = [
    '¡Excelente trabajo! Well done!',
    '¡Muy bien! You got it right!',
    '¡Fantástico! Great job!',
    '¡Increíble! Keep it up!',
    '¡Así se hace! That is correct!',
    '¡Buen trabajo! Very good!',
    '¡Acertaste! Perfect!',
    '¡Maravilloso! Awesome work!',
    '¡Genial! You are doing great!',
    '¡Brillante! Super good!',
    '¡Vas muy bien! Excellent!',
    '¡Correcto! Nice work!',
  ];

  static List<String> get availableEncouragements =>
      List.unmodifiable(_encouragements);

  /// Obtiene un mensaje alentador aleatorio garantizando que no se repita consecutivamente.
  static String getRandomEncouragement() {
    if (_encouragements.isEmpty) return '¡Muy bien! Well done!';
    if (_encouragements.length == 1) return _encouragements.first;

    int nextIndex;
    do {
      nextIndex = _random.nextInt(_encouragements.length);
    } while (nextIndex == _lastIndex);

    _lastIndex = nextIndex;
    return _encouragements[nextIndex];
  }
}
