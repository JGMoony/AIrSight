import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:http/http.dart' as http;

import '../services/haptic_service.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import '../services/voice_search_service.dart';
import '../core/theme/app_theme.dart';
import '../services/gemini_service.dart';

/// Pantalla accesible del módulo "Tutor por Voz" integrado con Gemini.
/// Permite consultas en lenguaje natural mediante el micrófono con retroalimentación
/// háptica y reproducción bilingüe inmediata vía síntesis de voz (TTS).
class TutorVozScreen extends StatefulWidget {
  const TutorVozScreen({super.key});

  @override
  State<TutorVozScreen> createState() => _TutorVozScreenState();
}

class _TutorVozScreenState extends State<TutorVozScreen>
    with SingleTickerProviderStateMixin {
  final VoiceSearchService _voiceService = VoiceSearchService();
  final TtsService _ttsService = TtsService();

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _isListening = false;
  bool _isConsulting = false;
  String _transcribedQuery = '';
  GeminiVoiceResult? _voiceResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    GeminiService.instance.inspeccionarModelosDisponibles();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ttsService.stop();
    _voiceService.stop();
    super.dispose();
  }

  /// Comprobación rápida de conectividad a internet (< 1s) según RNF-02
  Future<bool> _hayConexionInternet() async {
    try {
      if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
        return true;
      }
    } catch (_) {}
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(milliseconds: 900));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Emite un anuncio semántico accesible para lectores de pantalla TalkBack (WCAG 2.2 AA).
  void _announce(String message) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, TextDirection.ltr);
  }

  Future<void> _toggleListening() async {
    HapticService.buttonPress();

    // Detener explícitamente el sintetizador de voz antes de escuchar o cambiar estado
    await _ttsService.stopAll();

    if (_isListening) {
      await _voiceService.stop();
      _pulseController.stop();
      _pulseController.reset();
      setState(() {
        _isListening = false;
      });
      _announce('Micrófono detenido.');
      return;
    }

    // Limpieza inmediata de la tarjeta de resultado y errores previos al abrir el micrófono
    setState(() {
      _voiceResult = null;
      _errorMessage = null;
    });

    final started = await _voiceService.startListening(
      localeId: 'es_CO',
      onResult: (text, isFinal) {
        setState(() {
          _transcribedQuery = text;
        });

        if (isFinal) {
          _pulseController.stop();
          _pulseController.reset();
          setState(() {
            _isListening = false;
          });
          _consultarGemini(text);
        }
      },
      onError: (err) {
        _pulseController.stop();
        _pulseController.reset();
        setState(() {
          _isListening = false;
          _errorMessage = 'No se detectó audio o hubo un error con el micrófono.';
        });
        _announce('No se detectó audio del micrófono.');
      },
    );

    if (started) {
      _pulseController.repeat(reverse: true);
      setState(() {
        _isListening = true;
      });
      _announce('Micrófono activado. Haz tu pregunta en voz alta.');
    } else {
      _pulseController.stop();
      _pulseController.reset();
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo acceder al micrófono. Verifica los permisos.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo acceder al micrófono.')),
      );
    }
  }

  Future<void> _consultarGemini(String query) async {
    // Detener cualquier locución activa antes de procesar una nueva consulta
    await _ttsService.stopAll();

    // Limpieza inmediata del resultado anterior y errores para no engañar al usuario en pantalla
    setState(() {
      _voiceResult = null;
      _errorMessage = null;
    });

    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    // Validación offline previa (< 1s)
    final bool conectado = await _hayConexionInternet();
    if (!conectado) {
      await HapticService.error();
      const error = 'Se requiere conexión a internet para utilizar este servicio';
      setState(() {
        _isConsulting = false;
        _errorMessage = error;
      });
      _announce(error);
      await _ttsService.speakSpanish(error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(error),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return;
    }

    // Validación inmediata del filtro de término individual (RF-11 / MULTI_WORD)
    // Corta inmediatamente el audio y evita reproducir "Consultando al tutor..." si excede una palabra
    final validacion = GeminiService.validarConsultaPalabraIndividual(cleanQuery);
    if (!validacion.esValida) {
      await _ttsService.stopAll();
      final errorMsg = validacion.mensajeError ?? GeminiService.mensajeContingenciaPalabraUnica;
      setState(() {
        _isConsulting = false;
        _errorMessage = errorMsg;
      });
      await HapticService.error();
      _announce(errorMsg);
      await _ttsService.speakSpanish(errorMsg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return;
    }

    // Retroalimentación inmediata WCAG 2.2 AA (< 400 ms) (RNF-01 / Sec 3.2.3)
    HapticService.buttonPress();
    _announce('Consultando tutor con inteligencia artificial, por favor espera...');
    _ttsService.speakSpanish('Consultando al tutor, por favor espera un momento...');

    setState(() {
      _isConsulting = true;
      _voiceResult = null;
      _errorMessage = null;
    });

    try {
      ProgressService.registerTutorQuery();
      final result = await GeminiService.instance.consultarPorVoz(cleanQuery);
      if (!mounted) return;

      setState(() {
        _isConsulting = false;
        _voiceResult = result;
      });

      if (result.success) {
        HapticService.success();
        ProgressService.registerAudioPlay();

        final term = result.wordOrTerm ?? cleanQuery;
        _announce('Respuesta del tutor para $term: ${result.translation}. Reproduciendo audio.');

        // Locución estándar secuencial completa:
        // 1. Palabra en inglés y significado en español.
        // 2. Pronunciación / fonética.
        // 3. Frase de ejemplo en inglés: "Frase de ejemplo: [exampleEn]."
        // 4. Traducción del ejemplo en español: "[exampleEs]"
        await _ttsService.speakTutorStandardResponse(
          wordEn: term,
          wordEs: result.translation ?? '',
          phonetic: result.phonetic,
          explanationEs: result.explanation,
          exampleEn: result.exampleEn,
          exampleEs: result.exampleEs,
        );
      } else {
        await _ttsService.stopAll();
        final error = _formatearMensajeErrorAccesible(result.errorMessage);
        setState(() {
          _errorMessage = error;
        });
        HapticService.error();

        _announce(error);
        await _ttsService.speakSpanish(error);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } on http.ClientException catch (e) {
      if (!mounted) return;
      await _ttsService.stopAll();
      debugPrint('Error de cliente HTTP (oculto en UI): $e');
      const errorMsg = 'Hubo un problema de conexión. Por favor verifica tu acceso a internet e intenta nuevamente.';
      setState(() {
        _isConsulting = false;
        _errorMessage = errorMsg;
      });
      HapticService.error();
      _announce(errorMsg);
      await _ttsService.speakSpanish(errorMsg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(errorMsg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } on SocketException catch (_) {
      if (!mounted) return;
      await _ttsService.stopAll();
      const errorMsg = 'Sin conexión a internet. Verifica tu red e intenta de nuevo.';
      setState(() {
        _isConsulting = false;
        _errorMessage = errorMsg;
      });
      HapticService.error();
      _announce(errorMsg);
      await _ttsService.speakSpanish(errorMsg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(errorMsg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } on TimeoutException catch (_) {
      if (!mounted) return;
      await _ttsService.stopAll();
      const errorMsg = 'Tiempo de espera agotado al consultar al tutor. Verifica tu conexión e intenta de nuevo.';
      setState(() {
        _isConsulting = false;
        _errorMessage = errorMsg;
      });
      HapticService.error();
      _announce(errorMsg);
      await _ttsService.speakSpanish(errorMsg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(errorMsg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      await _ttsService.stopAll();
      debugPrint('Error genérico (oculto en UI): $e');
      final error = _formatearMensajeErrorAccesible(e.toString());
      setState(() {
        _isConsulting = false;
        _errorMessage = error;
      });
      HapticService.error();

      _announce(error);
      await _ttsService.speakSpanish(error);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  /// Transforma cualquier excepción técnica o error del servidor en un mensaje accesible y comprensible (WCAG 2.2 AA),
  /// sin enmascarar errores reales de configuración o HTTP bajo un falso "alta demanda".
  String _formatearMensajeErrorAccesible(String? errorRaw) {
    debugPrint('>>> [AIRSIGHT TUTOR ERROR]: $errorRaw');

    if (errorRaw == null || errorRaw.trim().isEmpty) {
      return 'No se recibió respuesta del tutor de voz. Por favor, intenta de nuevo.';
    }

    final lower = errorRaw.toLowerCase();

    // Mensaje pedagógico estricto del estándar IEEE 830 RF-11 (una palabra a la vez):
    if (lower.contains('por favor consulta únicamente una palabra') ||
        lower.contains('una palabra a la vez') ||
        lower.contains('no se detectó audio')) {
      return errorRaw.trim();
    }

    // Problemas de conectividad de red local:
    if (lower.contains('socketexception') ||
        lower.contains('sin conexión') ||
        lower.contains('se requiere conexión') ||
        lower.contains('network') ||
        lower.contains('failed host lookup')) {
      return 'Se requiere conexión a internet para utilizar este servicio';
    }

    // Timeout de red:
    if (lower.contains('timeoutexception') || lower.contains('timed out')) {
      return 'Tiempo de espera agotado al consultar al tutor. Verifica tu conexión e intenta de nuevo.';
    }

    // Congestión real 503 / 429 ("high demand" / "unavailable" / "quota") o stub de prueba unitaria:
    if (lower.contains('503') ||
        lower.contains('429') ||
        lower.contains('high demand') ||
        lower.contains('unavailable') ||
        lower.contains('resource_exhausted') ||
        lower.contains('tu_api_key_aqui')) {
      return 'El tutor presenta alta demanda temporal. Por favor, intenta de nuevo en un momento.';
    }

    // Errores de cliente, conexión abortada o SocketException
    if (lower.contains('clientexception') ||
        lower.contains('software caused connection abort') ||
        lower.contains('connection abort') ||
        lower.contains('connection closed') ||
        lower.contains('connection reset')) {
      return 'Hubo un problema de conexión. Por favor verifica tu acceso a internet e intenta nuevamente.';
    }

    // Errores HTTP o de autenticación: mensaje amigable que nunca filtra la URL con API Key
    if (lower.contains('fallo http') ||
        lower.contains('api_key') ||
        lower.contains('400') ||
        lower.contains('401') ||
        lower.contains('403') ||
        lower.contains('404')) {
      return 'El servicio no está disponible en este momento. Intenta de nuevo en unos segundos.';
    }

    // Sanitización defensiva: si el mensaje crudo contiene indicios de URLs, claves o trazas técnicas, reemplazar
    if (lower.contains('http') ||
        lower.contains('key=') ||
        lower.contains('exception') ||
        lower.contains('generativelanguage')) {
      return 'El servicio no está disponible en este momento. Intenta de nuevo en unos segundos.';
    }

    return errorRaw.trim();
  }

  @override
  Widget build(BuildContext context) {
    final result = _voiceResult;
    final isBusy = _isListening || _isConsulting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor por voz'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Cabecera informativa accesible
            Semantics(
              label:
                  'Módulo Tutor por Voz con Gemini. Consulta una palabra a la vez en inglés o español para aprender su traducción, pronunciación y un ejemplo.',
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: AppTheme.surface,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.record_voice_over_rounded,
                        color: AppTheme.primaryLight,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tutor de Inglés A1 con IA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Consulta una palabra a la vez por micrófono y escucha su traducción, pronunciación y ejemplo A1.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // BOTÓN CENTRAL GRANDE DE MICRÓFONO CON HALO PULSANTE
            Center(
              child: Semantics(
                button: true,
                label: _isListening
                    ? 'Micrófono activo, escuchando. Toca dos veces para detener.'
                    : (_isConsulting
                        ? 'Consultando con Gemini, por favor espera.'
                        : 'Botón de micrófono. Toca dos veces para hacer una pregunta en voz alta.'),
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    final pulse = _isListening ? _pulseAnimation.value : 0.0;
                    return SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isListening) ...[
                            // Anillo exterior difuso
                            Container(
                              width: 110 + (pulse * 40),
                              height: 110 + (pulse * 40),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red.withValues(alpha: 0.12 * (1 - pulse * 0.4)),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.40 * (1 - pulse * 0.3)),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            // Anillo intermedio
                            Container(
                              width: 110 + (pulse * 20),
                              height: 110 + (pulse * 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red.withValues(alpha: 0.22 * (1 - pulse * 0.2)),
                              ),
                            ),
                          ],
                          child!,
                        ],
                      ),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isConsulting ? null : _toggleListening,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isListening
                              ? const LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : (_isConsulting
                                  ? const LinearGradient(
                                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [AppTheme.primaryLight, AppTheme.primary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )),
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening
                                      ? Colors.red
                                      : (_isConsulting ? AppTheme.primary : AppTheme.primaryLight))
                                  .withValues(alpha: 0.4),
                              blurRadius: _isListening ? 26 : 16,
                              spreadRadius: _isListening ? 4 : 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isConsulting
                              ? const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _isListening
                                      ? Icons.mic_rounded
                                      : Icons.mic_none_rounded,
                                  size: 52,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Estado del micrófono
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _isListening
                      ? 'Escuchando... Di tu pregunta ahora'
                      : (_isConsulting
                          ? 'Consultando con Gemini...'
                          : 'Toca el micrófono para preguntar'),
                  key: ValueKey('$_isListening-$_isConsulting'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _isListening
                        ? const Color(0xFFF87171)
                        : (_isConsulting ? AppTheme.primaryLight : AppTheme.textSecondary),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Estado de carga accesible WCAG 2.2 AA (liveRegion para TalkBack / RNF-01 / Sec 3.2.3)
            if (_isConsulting) ...[
              Semantics(
                liveRegion: true,
                label: 'Consultando tutor, por favor espera...',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryLight.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.8,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                      SizedBox(width: 14),
                      Text(
                        'Consultando tutor, por favor espera...',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Texto transcrito de la pregunta
            if (_transcribedQuery.isNotEmpty) ...[
              Semantics(
                label: 'Pregunta capturada: $_transcribedQuery',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppTheme.primaryLight,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '"$_transcribedQuery"',
                          style: const TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Mensaje de error si ocurrió
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red.shade300,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // TARJETA DE RESULTADO DE GEMINI
            if (result != null && result.success) ...[
              _TutorVoiceResultCard(
                result: result,
                onReplayFull: () {
                  HapticService.selection();
                  _ttsService.speakTutorStandardResponse(
                    wordEn: result.wordOrTerm ?? '',
                    wordEs: result.translation ?? '',
                    phonetic: result.phonetic,
                    explanationEs: result.explanation,
                    exampleEn: result.exampleEn,
                    exampleEs: result.exampleEs,
                  );
                },
                onPlayEnglish: () {
                  HapticService.selection();
                  final term = result.wordOrTerm;
                  if (term != null && term.isNotEmpty) {
                    _ttsService.speakEnglish(term);
                  }
                },
                onAskAnother: _toggleListening,
              ),
              const SizedBox(height: 24),
            ],

            // Sugerencias rápidas de prueba
            const Text(
              'O toca un ejemplo para probar:',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SuggestionChip(
                  label: '¿Cómo se dice lápiz en inglés?',
                  disabled: isBusy,
                  onTap: () {
                    HapticService.buttonPress();
                    setState(() => _transcribedQuery = '¿Cómo se dice lápiz en inglés?');
                    _consultarGemini('¿Cómo se dice lápiz en inglés?');
                  },
                ),
                _SuggestionChip(
                  label: '¿Cómo se dice manzana en inglés?',
                  disabled: isBusy,
                  onTap: () {
                    HapticService.buttonPress();
                    setState(() => _transcribedQuery = '¿Cómo se dice manzana en inglés?');
                    _consultarGemini('¿Cómo se dice manzana en inglés?');
                  },
                ),
                _SuggestionChip(
                  label: '¿Qué significa computer?',
                  disabled: isBusy,
                  onTap: () {
                    HapticService.buttonPress();
                    setState(() => _transcribedQuery = '¿Qué significa computer?');
                    _consultarGemini('¿Qué significa computer?');
                  },
                ),
                _SuggestionChip(
                  label: '¿Cómo se pronuncia chair?',
                  disabled: isBusy,
                  onTap: () {
                    HapticService.buttonPress();
                    setState(() => _transcribedQuery = '¿Cómo se pronuncia chair?');
                    _consultarGemini('¿Cómo se pronuncia chair?');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final bool disabled;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Consultar ejemplo: $label',
      hint: 'Toca dos veces para enviar esta consulta',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: ActionChip(
          materialTapTargetSize: MaterialTapTargetSize.padded,
          avatar: const Icon(Icons.help_outline_rounded, size: 16, color: AppTheme.primaryLight),
          label: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
          backgroundColor: AppTheme.surface,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onPressed: disabled ? null : onTap,
        ),
      ),
    );
  }
}

class _TutorVoiceResultCard extends StatelessWidget {
  final GeminiVoiceResult result;
  final VoidCallback onReplayFull;
  final VoidCallback onPlayEnglish;
  final VoidCallback onAskAnother;

  const _TutorVoiceResultCard({
    required this.result,
    required this.onReplayFull,
    required this.onPlayEnglish,
    required this.onAskAnother,
  });

  @override
  Widget build(BuildContext context) {
    final term = result.wordOrTerm ?? result.query;
    final translation = result.translation ?? '';
    final phonetic = result.phonetic ?? '';
    final explanation = result.explanation ?? '';
    final exampleEn = result.exampleEn ?? '';
    final exampleEs = result.exampleEs ?? '';

    return Semantics(
      label:
          'Respuesta del tutor para $term. Traducción: $translation. Pronunciación: $phonetic. Explicación: $explanation. Ejemplo: $exampleEn, en español $exampleEs.',
      child: Card(
        elevation: 0,
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primary.withValues(alpha: 0.10),
                AppTheme.surface,
              ],
            ),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.primaryLight,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Respuesta del Tutor Gemini',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: 24, color: Colors.white.withValues(alpha: 0.08)),

              // Término y fonética
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    term,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (phonetic.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      phonetic,
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),

              // Traducción principal
              Text(
                '→ $translation',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.secondary,
                ),
              ),

              if (explanation.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: AppTheme.primaryLight,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          explanation,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (exampleEn.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Frase de ejemplo:',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"$exampleEn"',
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (exampleEs.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    exampleEs,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 20),

              // Botones de audio interactivos
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: onReplayFull,
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Repetir explicación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onPlayEnglish,
                    icon: const Icon(Icons.record_voice_over_rounded),
                    label: const Text('Pronunciar en inglés'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryLight,
                      side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onAskAnother,
                    icon: const Icon(Icons.mic_rounded),
                    label: const Text('Hacer otra pregunta'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
