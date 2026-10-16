import 'package:flutter/material.dart';

import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../glossary/glossary_data.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final TtsService _ttsService = TtsService.instance;
  late Future<ProgressSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _loadSummary() {
    _summaryFuture = ProgressService.getSummary();
  }

  void _reload() {
    setState(_loadSummary);
  }

  double _calculateWordProgress(int wordsViewed) {
    if (glossaryWords.isEmpty) return 0.0;
    final progress = wordsViewed / glossaryWords.length;
    return progress.clamp(0.0, 1.0);
  }

  String _formatLastAccess(String lastAccess) {
    if (lastAccess.trim().isEmpty) {
      return 'Sin registros todavía';
    }

    return lastAccess;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso'),
      ),
      body: FutureBuilder<ProgressSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              onRetry: _reload,
            );
          }

          final summary = snapshot.data ?? ProgressSummary.empty();

          final wordProgress = _calculateWordProgress(summary.wordsViewed);
          final successPercent = (summary.successRate * 100).round();
          final totalWordsCatalog = glossaryWords.length;

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Semantics(
                    label: 'Escuchar mi progreso completo',
                    hint: 'Toca dos veces para escuchar un resumen hablado de tu aprendizaje',
                    button: true,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        _ttsService.speakSpanish(
                          'Tu progreso actual es: ${summary.wordsViewed} palabras exploradas, ${summary.audioPlays} audios nativos reproducidos, ${summary.correctAnswers} aciertos en prácticas y ${summary.tutorQueries} consultas realizadas al tutor de voz.',
                        );
                      },
                      icon: const Icon(Icons.volume_up_rounded, size: 28),
                      label: const Text(
                        'Escuchar mi progreso',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _SummaryCard(
                    wordsViewed: summary.wordsViewed,
                    totalWordsGoal: totalWordsCatalog,
                    progressValue: wordProgress,
                    lastAccess: _formatLastAccess(summary.lastAccess),
                  ),

                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.25,
                    children: [
                      _StatCard(
                        label: 'Palabras vistas',
                        value: '${summary.wordsViewed}',
                        icon: Icons.menu_book_rounded,
                      ),
                      _StatCard(
                        label: 'Audios reproducidos',
                        value: '${summary.audioPlays}',
                        icon: Icons.volume_up_rounded,
                      ),
                      _StatCard(
                        label: 'Prácticas',
                        value: '${summary.practiceCompleted}',
                        icon: Icons.quiz_rounded,
                      ),
                      _StatCard(
                        label: 'Usos de cámara',
                        value: '${summary.cameraUses}',
                        icon: Icons.camera_alt_rounded,
                      ),
                      _StatCard(
                        label: 'Consultas al tutor',
                        value: '${summary.tutorQueries}',
                        icon: Icons.record_voice_over_rounded,
                      ),
                      _StatCard(
                        label: 'Aciertos práctica',
                        value: '${summary.correctAnswers}',
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _PracticeResultsCard(
                    correctAnswers: summary.correctAnswers,
                    incorrectAnswers: summary.incorrectAnswers,
                    successPercent: successPercent,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int wordsViewed;
  final int totalWordsGoal;
  final double progressValue;
  final String lastAccess;

  const _SummaryCard({
    required this.wordsViewed,
    required this.totalWordsGoal,
    required this.progressValue,
    required this.lastAccess,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Resumen de aprendizaje. $wordsViewed de $totalWordsGoal palabras consultadas. Último uso: $lastAccess',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen de aprendizaje',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Último uso: $lastAccess',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: progressValue,
                minHeight: 12,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 10),
              Text('$wordsViewed de $totalWordsGoal palabras consultadas'),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeResultsCard extends StatelessWidget {
  final int correctAnswers;
  final int incorrectAnswers;
  final int successPercent;

  const _PracticeResultsCard({
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.successPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Resultados de práctica. Aciertos: $correctAnswers. Errores: $incorrectAnswers. Porcentaje de acierto: $successPercent por ciento.',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resultados de práctica',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text('Aciertos: $correctAnswers'),
              Text('Errores: $incorrectAnswers'),
              Text('Porcentaje de acierto: $successPercent%'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: AppTheme.primary,
                size: 30,
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            const Text(
              'No se pudo cargar el progreso.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}