import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../core/theme/app_theme.dart';
import '../../services/encouragement_service.dart';
import '../../services/haptic_service.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../glossary/glossary_data.dart';
import '../glossary/glossary_word.dart';

class _TrueFalseQuestion {
  final GlossaryWord word;
  final String shownTranslation;
  final bool isActuallyTrue;

  const _TrueFalseQuestion({
    required this.word,
    required this.shownTranslation,
    required this.isActuallyTrue,
  });
}

/// Pantalla de práctica gamificada: "Verdadero o Falso" (True or False) (WCAG 2.2 AA).
/// Presenta desafíos de asociación directa bilingüe con touch targets amplios (>= 64 dp),
/// feedback auditivo por TTS y vibración háptica diferenciada para acierto y error.
class TrueFalsePracticeScreen extends StatefulWidget {
  final int questionLimit;

  const TrueFalsePracticeScreen({
    super.key,
    this.questionLimit = 10,
  });

  @override
  State<TrueFalsePracticeScreen> createState() => _TrueFalsePracticeScreenState();
}

class _TrueFalsePracticeScreenState extends State<TrueFalsePracticeScreen> {
  final TtsService _ttsService = TtsService();
  final Random _random = Random();

  late final List<_TrueFalseQuestion> _questions;
  int _currentIndex = 0;
  int _correctCount = 0;
  int _incorrectCount = 0;

  bool _answered = false;
  bool? _wasCorrect;
  bool _canPop = false;
  String _currentEncouragement = '¡Excelente trabajo! Well done!';

  void _announce(String message) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, TextDirection.ltr);
  }

  @override
  void initState() {
    super.initState();
    _buildQuestions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _speakCurrentChallenge();
      }
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _buildQuestions() {
    final pool = List<GlossaryWord>.from(glossaryWords)..shuffle(_random);
    final count = min(widget.questionLimit, pool.length);
    final selectedWords = pool.take(count).toList();

    _questions = [];

    for (int i = 0; i < selectedWords.length; i++) {
      final word = selectedWords[i];
      // 50% de probabilidad de ser verdadero, 50% falso
      final isTrue = i % 2 == 0 ? _random.nextBool() : (i % 2 == 1);

      if (isTrue) {
        _questions.add(
          _TrueFalseQuestion(
            word: word,
            shownTranslation: word.wordEs,
            isActuallyTrue: true,
          ),
        );
      } else {
        // Seleccionar una traducción de otra palabra distinta
        final otherWords = pool.where((w) => w.id != word.id && w.wordEs != word.wordEs).toList();
        otherWords.shuffle(_random);
        final distractor = otherWords.isNotEmpty ? otherWords.first.wordEs : 'Desconocido';

        _questions.add(
          _TrueFalseQuestion(
            word: word,
            shownTranslation: distractor,
            isActuallyTrue: false,
          ),
        );
      }
    }

    _questions.shuffle(_random);
  }

  _TrueFalseQuestion get _currentQuestion => _questions[_currentIndex];

  Future<void> _speakCurrentChallenge() async {
    final q = _currentQuestion;
    final textToSpeak = '${q.word.wordEn} significa ${q.shownTranslation}. ¿Es verdadero o falso?';
    _announce(textToSpeak);
    await _ttsService.speakSpanish(textToSpeak);
  }

  Future<void> _handleAnswer(bool userAnswer) async {
    if (_answered) return;

    final q = _currentQuestion;
    final isCorrect = (userAnswer == q.isActuallyTrue);

    if (isCorrect) {
      await HapticService.success();
    } else {
      await HapticService.error();
    }

    setState(() {
      _answered = true;
      _wasCorrect = isCorrect;

      if (isCorrect) {
        _correctCount++;
      } else {
        _incorrectCount++;
      }
    });

    await ProgressService.registerPracticeAnswer(isCorrect: isCorrect);

    if (isCorrect) {
      _currentEncouragement = EncouragementService.getRandomEncouragement();
      _announce('$_currentEncouragement Respuesta acertada.');
      await _ttsService.speakSpanish(_currentEncouragement);
    } else {
      final explanation = q.isActuallyTrue
          ? 'Es verdadero. ${q.word.wordEn} sí significa ${q.word.wordEs}.'
          : 'Es falso. ${q.word.wordEn} no significa ${q.shownTranslation}, significa ${q.word.wordEs}.';

      _announce('Incorrecto. $explanation');
      await _ttsService.speakSpanish('¡Buen intento! $explanation ¡Sigamos!');
    }
  }

  void _nextQuestion() {
    HapticService.selection();
    if (_currentIndex + 1 >= _questions.length) {
      _showFinalResults();
      return;
    }

    setState(() {
      _currentIndex++;
      _answered = false;
      _wasCorrect = null;
    });

    _speakCurrentChallenge();
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    await HapticService.selection();
    _announce('¿Deseas hacer una pausa? Si sales ahora no se guardará el avance de esta ronda.');
    if (!context.mounted) return false;

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.pause_circle_outline_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '¿Hacer una pausa?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'Si sales ahora, no se guardará el avance de esta sesión de práctica. ¿Quieres seguir practicando?',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(120, 48),
            ),
            onPressed: () {
              HapticService.selection();
              Navigator.of(ctx).pop(false);
            },
            child: const Text(
              'Seguir practicando',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 48),
            ),
            onPressed: () {
              HapticService.selection();
              Navigator.of(ctx).pop(true);
            },
            child: const Text(
              'Pausar y salir',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _showFinalResults() async {
    _canPop = true;
    await HapticService.success();
    await _ttsService.playVictorySound();
    _announce('¡Desafío completado! Obtuviste $_correctCount respuestas correctas de ${_questions.length}.');
    await _ttsService.speakPracticeSummary(
      totalPreguntas: _questions.length,
      totalAciertos: _correctCount,
      totalFallos: _incorrectCount,
    );

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Gran trabajo! Práctica completada'),
        content: Text(
          '¡Felicitaciones por tu esfuerzo!\n\n'
          'Respuestas correctas: $_correctCount\n'
          'Preguntas para repasar: $_incorrectCount\n'
          'Total de preguntas: ${_questions.length}',
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(48, 48),
            ),
            onPressed: () {
              HapticService.buttonPress();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Volver a prácticas'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verdadero o Falso')),
        body: const Center(child: Text('No hay preguntas disponibles.')),
      );
    }

    final q = _currentQuestion;
    final total = _questions.length;
    final progress = (_currentIndex + 1) / total;

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldExit = await _showExitConfirmationDialog(context);
        if (shouldExit && context.mounted) {
          setState(() {
            _canPop = true;
          });
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verdadero o Falso'),
          leading: Semantics(
            label: 'Salir de la práctica, botón',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Salir de la práctica',
              onPressed: () async {
                final bool shouldExit = await _showExitConfirmationDialog(context);
                if (shouldExit && context.mounted) {
                  setState(() {
                    _canPop = true;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de Progreso
              Semantics(
                label: 'Pregunta ${_currentIndex + 1} de $total',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pregunta ${_currentIndex + 1} de $total',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          'Aciertos: $_correctCount',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tarjeta del Desafío (altura natural para ceder el máximo espacio libre a los botones)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          q.word.category,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Enunciado
                      Semantics(
                        header: true,
                        label: 'Enunciado del desafío: ${q.word.wordEn} significa ${q.shownTranslation}',
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '"${q.word.wordEn}"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'significa',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '"${q.shownTranslation}"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Botón: Escuchar Desafío
                      Semantics(
                        label: 'Escuchar desafío con voz alta, botón',
                        button: true,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(180, 42),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _speakCurrentChallenge,
                          icon: const Icon(Icons.volume_up_rounded, color: AppTheme.primary, size: 20),
                          label: const Text(
                            'Escuchar desafío',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Área Interactiva Expandida (Ocupa el 100% del espacio libre restante)
              Expanded(
                child: !_answered
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Botón VERDADERO (50% de la pantalla libre)
                          Expanded(
                            child: Semantics(
                              label: 'Opción Verdadero, botón de pantalla completa superior',
                              button: true,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.success,
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                                onPressed: () => _handleAnswer(true),
                                icon: const Icon(Icons.check_circle_rounded, size: 36),
                                label: const Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'VERDADERO',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Botón FALSO (50% de la pantalla libre)
                          Expanded(
                            child: Semantics(
                              label: 'Opción Falso, botón de pantalla completa inferior',
                              button: true,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.error,
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                                onPressed: () => _handleAnswer(false),
                                icon: const Icon(Icons.cancel_rounded, size: 36),
                                label: const Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'FALSO',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tarjeta de Feedback tras responder
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: (_wasCorrect == true ? Colors.green : Colors.red)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _wasCorrect == true ? Colors.green : Colors.red,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _wasCorrect == true
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: _wasCorrect == true ? Colors.green : Colors.red,
                                  size: 32,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _wasCorrect == true ? _currentEncouragement : 'Respuesta Incorrecta',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          color: _wasCorrect == true
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${q.word.wordEn} significa ${q.word.wordEs}.',
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          // Botón Siguiente Pregunta con touch target adaptable
                          Semantics(
                            label: _currentIndex + 1 >= _questions.length
                                ? 'Ver resultados finales, botón'
                                : 'Pasar a la siguiente pregunta, botón',
                            button: true,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 56),
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: _nextQuestion,
                                icon: const Icon(Icons.arrow_forward_rounded, size: 26),
                                label: Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _currentIndex + 1 >= _questions.length
                                          ? 'VER RESULTADOS'
                                          : 'SIGUIENTE PREGUNTA',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    ),
  );
}
}
