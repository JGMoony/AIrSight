import 'package:flutter/material.dart';

import '../../core/services/haptic_service.dart';
import '../../core/services/progress_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import 'glossary_word.dart';

class GlossaryDetailScreen extends StatefulWidget {
  final GlossaryWord word;

  const GlossaryDetailScreen({
    super.key,
    required this.word,
  });

  @override
  State<GlossaryDetailScreen> createState() => _GlossaryDetailScreenState();
}

class _GlossaryDetailScreenState extends State<GlossaryDetailScreen> {
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    ProgressService.registerWordViewed(widget.word.id);
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _speakEnglishNormal() async {
    await HapticService.selection();
    await ProgressService.registerAudioPlay();
    await _ttsService.speakEnglish(widget.word.wordEn);
  }

  Future<void> _speakEnglishSlow() async {
    await HapticService.selection();
    await ProgressService.registerAudioPlay();
    await _ttsService.speakEnglishSlow(widget.word.wordEn);
  }

  Future<void> _speakSpanishWord() async {
    await HapticService.selection();
    await ProgressService.registerAudioPlay();
    await _ttsService.speakSpanish(widget.word.wordEs);
  }

  Future<void> _speakExample() async {
    await HapticService.selection();
    await ProgressService.registerAudioPlay();

    // Secuencia asíncrona de audio TTS:
    // 1. Detiene cualquier locución previa del motor TTS.
    // 2. Reproduce la oración en inglés (en-US).
    // 3. Espera la finalización completa con awaitSpeakCompletion.
    // 4. Pausa de cortesía (~300 ms).
    // 5. Reproduce la traducción contextual completa en español (es-ES).
    await _ttsService.speakBilingual(
      textEn: widget.word.exampleEn,
      textEs: widget.word.exampleEs,
      pause: const Duration(milliseconds: 300),
    );
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'classroom':
        return const Color(0xFF2ECC71);
      case 'home':
        return const Color(0xFFFFA726);
      case 'food':
        return const Color(0xFFE91E63);
      case 'colors':
        return const Color(0xFF8E67F0);
      case 'numbers':
        return const Color(0xFF42A5F5);
      case 'body':
        return const Color(0xFFFF7043);
      case 'objects':
        return const Color(0xFF26A69A);
      case 'animals':
        return const Color(0xFF8D6E63);
      case 'clothes':
        return const Color(0xFF607D8B);
      case 'people':
        return const Color(0xFF5C6BC0);
      case 'places':
        return const Color(0xFF009688);
      case 'nature':
        return const Color(0xFF66BB6A);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.word;
    final categoryColor = _categoryColor(word.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(word.wordEn),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Semantics(
              label:
                  'Detalle de palabra. ${word.wordEn}. Traducción: ${word.wordEs}. Categoría: ${word.category}. Ejemplo en inglés: ${word.exampleEn}. Traducción del ejemplo: ${word.exampleEs}.',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          word.category,
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        word.wordEn,
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        word.wordEs,
                        style: const TextStyle(
                          fontSize: 25,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Ejemplo de uso',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Línea 1: Oración en inglés con énfasis tipográfico
                      Text(
                        word.exampleEn,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1.35,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Línea 2: Traducción contextual íntegra al español (contraste accesible WCAG 2.2 AA)
                      Text(
                        word.exampleEs,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Encabezado de la sección de controles de audio
            Semantics(
              header: true,
              label: 'Controles de pronunciación y audio',
              child: const Text(
                'Pronunciación',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Agrupación de botones de inglés: velocidad normal y lenta
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Escuchar ${word.wordEn} a velocidad normal',
                    child: ElevatedButton.icon(
                      onPressed: _speakEnglishNormal,
                      icon: const Icon(Icons.volume_up_rounded),
                      label: const Text('Normal'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Escuchar ${word.wordEn} a velocidad lenta',
                    child: OutlinedButton.icon(
                      onPressed: _speakEnglishSlow,
                      icon: const Icon(Icons.slow_motion_video_rounded),
                      label: const Text('Lenta'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Pronunciación en español
            Semantics(
              button: true,
              label: 'Escuchar ${word.wordEs} en español',
              child: OutlinedButton.icon(
                onPressed: _speakSpanishWord,
                icon: const Icon(Icons.translate_rounded),
                label: Text('Español: "${word.wordEs}"'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Botón de ejemplo bilingüe (único botón de ejemplo, sin botón redundante de detener)
            Semantics(
              button: true,
              label: 'Escuchar ejemplo de uso en inglés y español',
              child: FilledButton.icon(
                onPressed: _speakExample,
                icon: const Icon(Icons.record_voice_over_rounded),
                label: const Text('Escuchar ejemplo bilingüe'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}