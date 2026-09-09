import 'package:flutter/material.dart';

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
    await ProgressService.registerAudioPlay();
    await _ttsService.speakEnglish(widget.word.wordEn);
  }

  Future<void> _speakEnglishSlow() async {
    await ProgressService.registerAudioPlay();
    await _ttsService.speakEnglishSlow(widget.word.wordEn);
  }

  Future<void> _speakSpanishWord() async {
    await ProgressService.registerAudioPlay();
    await _ttsService.speakSpanish(widget.word.wordEs);
  }

  Future<void> _speakExample() async {
    await ProgressService.registerAudioPlay();

    await _ttsService.speakEnglish(widget.word.example);

    await Future.delayed(const Duration(milliseconds: 800));

    await _ttsService.speakSpanish(
      '${widget.word.wordEn} significa ${widget.word.wordEs}.',
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
                  'Detalle de palabra. ${word.wordEn}. Traducción ${word.wordEs}. Categoría ${word.category}. Ejemplo en inglés: ${word.example}',
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
                          color: categoryColor.withOpacity(0.12),
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
                      Text(
                        word.example,
                        style: const TextStyle(
                          fontSize: 19,
                          height: 1.35,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${word.wordEn} significa ${word.wordEs}.',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.35,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            Semantics(
              button: true,
              label: 'Escuchar palabra en inglés normal ${word.wordEn}',
              child: ElevatedButton.icon(
                onPressed: _speakEnglishNormal,
                icon: const Icon(Icons.volume_up_rounded),
                label: Text('Escuchar "${word.wordEn}"'),
              ),
            ),

            const SizedBox(height: 12),

            Semantics(
              button: true,
              label: 'Escuchar palabra en inglés lentamente ${word.wordEn}',
              child: OutlinedButton.icon(
                onPressed: _speakEnglishSlow,
                icon: const Icon(Icons.slow_motion_video_rounded),
                label: const Text('Escuchar en inglés lento'),
              ),
            ),

            const SizedBox(height: 12),

            Semantics(
              button: true,
              label: 'Escuchar palabra en español ${word.wordEs}',
              child: OutlinedButton.icon(
                onPressed: _speakSpanishWord,
                icon: const Icon(Icons.translate_rounded),
                label: Text('Escuchar "${word.wordEs}"'),
              ),
            ),

            const SizedBox(height: 12),

            Semantics(
              button: true,
              label:
                  'Escuchar ejemplo en inglés y explicación en español para ${word.wordEn}',
              child: ElevatedButton.icon(
                onPressed: _speakExample,
                icon: const Icon(Icons.record_voice_over_rounded),
                label: const Text('Escuchar ejemplo bilingüe'),
              ),
            ),

            const SizedBox(height: 12),

            Semantics(
              button: true,
              label: 'Detener audio',
              child: TextButton.icon(
                onPressed: _ttsService.stop,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Detener audio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}