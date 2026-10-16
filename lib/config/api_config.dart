/// Configuración centralizada de credenciales y APIs externas del sistema Air Sight.
/// Mantiene las llaves de acceso en el entorno interno de la aplicación para garantizar
/// una experiencia 100% transparente y accesible para personas con discapacidad visual,
/// sin requerir interacción técnica ni solicitud manual de credenciales en la interfaz.
class ApiConfig {
  ApiConfig._();

  /// Clave de API de Google AI Studio para el modelo Gemini Flash.
  /// Puede inyectarse en compilación con `--dart-define=GEMINI_API_KEY=tu_clave`
  /// o configurarse aquí en defaultValue.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Indica si la clave de API está configurada con un valor válido (no vacío ni placeholder).
  static bool get isGeminiConfigured =>
      geminiApiKey.trim().isNotEmpty &&
      geminiApiKey != 'TU_API_KEY_AQUI';
}
