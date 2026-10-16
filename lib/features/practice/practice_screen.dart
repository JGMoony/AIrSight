import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/haptic_service.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../glossary/glossary_data.dart';
import '../glossary/glossary_word.dart';

enum PracticeStep {
  modeSelection,
  setup,
  playing,
}

class PracticeScreen extends StatefulWidget {
  final String? initialMode;

  const PracticeScreen({
    super.key,
    this.initialMode,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final TtsService _ttsService = TtsService();
  final Random _random = Random();

  final List<int> _questionLimits = [5, 10, 15, 20];

  late List<String> _categories;

  PracticeStep _currentStep = PracticeStep.modeSelection;
  String? _selectedMode;
  String _selectedCategory = 'Aleatorio';
  int _selectedQuestionLimit = 5;

  bool _answered = false;
  bool? _wasCorrect;

  int _currentQuestionIndex = 0;
  int _correctCount = 0;
  int _incorrectCount = 0;

  String? _selectedWordId;

  late List<GlossaryWord> _practicePool;
  late GlossaryWord _currentWord;
  late List<GlossaryWord> _options;

  @override
  void initState() {
    super.initState();

    _categories = [
      'Aleatorio',
      ...glossaryWords.map((word) => word.category).toSet().toList()..sort(),
    ];

    if (widget.initialMode != null) {
      _selectedMode = widget.initialMode;
      _currentStep = PracticeStep.setup;
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _chooseMode(String mode) {
    HapticService.buttonPress();
    setState(() {
      _selectedMode = mode;
      _currentStep = PracticeStep.setup;
    });
  }

  void _backToModeSelection() {
    HapticService.selection();
    _ttsService.stop();
    setState(() {
      _selectedMode = null;
      _currentStep = PracticeStep.modeSelection;
    });
  }

  void _startPractice() {
    HapticService.buttonPress();
    final filteredWords = _selectedCategory == 'Aleatorio'
        ? List<GlossaryWord>.from(glossaryWords)
        : glossaryWords
            .where((word) => word.category == _selectedCategory)
            .toList();

    if (filteredWords.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta categoría necesita al menos 4 palabras para practicar.',
          ),
        ),
      );
      return;
    }

    filteredWords.shuffle(_random);

    setState(() {
      _practicePool = filteredWords;
      _currentStep = PracticeStep.playing;
      _currentQuestionIndex = 0;
      _correctCount = 0;
      _incorrectCount = 0;
      _generateQuestion();
    });
  }

  void _generateQuestion() {
    final words = List<GlossaryWord>.from(_practicePool);
    words.shuffle(_random);

    _currentWord = words.first;

    final wrongCount = _selectedMode == 'Completar la frase' ? 2 : 3;
    final wrongOptions = words
        .where((word) => word.id != _currentWord.id)
        .take(wrongCount)
        .toList();

    _options = [_currentWord, ...wrongOptions];
    _options.shuffle(_random);

    _answered = false;
    _wasCorrect = null;
    _selectedWordId = null;

    // Locución accesible de instrucción al iniciar cada ejercicio (RF-08)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentStep != PracticeStep.playing) return;
      if (_selectedMode == 'Completar la frase') {
        _ttsService.speakSpanish('Completa la frase con la palabra correcta.');
      } else {
        _ttsService.speakSpanish('Escucha con atención la palabra en inglés y selecciona el significado correcto.');
      }
    });
  }

  Future<void> _playQuestionAudio() async {
    await HapticService.selection();
    if (_selectedMode == 'Completar la frase') {
      await _ttsService.speakSentenceWithBlank(
        sentenceWithBlank: _sentenceWithBlank,
        slow: false,
      );
    } else {
      await _ttsService.speakEnglish(_currentWord.wordEn);
    }
    await ProgressService.registerAudioPlay();
  }

  Future<void> _playQuestionAudioSlow() async {
    await HapticService.selection();
    if (_selectedMode == 'Completar la frase') {
      await _ttsService.speakSentenceWithBlank(
        sentenceWithBlank: _sentenceWithBlank,
        slow: true,
      );
    } else {
      await _ttsService.speakEnglishSlow(_currentWord.wordEn);
    }
    await ProgressService.registerAudioPlay();
  }

  String get _sentenceWithBlank {
    final en = _currentWord.exampleEn;
    final pattern = RegExp(RegExp.escape(_currentWord.wordEn), caseSensitive: false);
    if (pattern.hasMatch(en)) {
      return en.replaceFirst(pattern, '_____');
    }
    return 'The _____ is here.';
  }

  Future<void> _selectAnswer(GlossaryWord selectedWord) async {
    if (_answered) return;

    final isCorrect = selectedWord.id == _currentWord.id;

    if (isCorrect) {
      await HapticService.success();
    } else {
      await HapticService.error();
    }

    setState(() {
      _answered = true;
      _wasCorrect = isCorrect;
      _selectedWordId = selectedWord.id;

      if (isCorrect) {
        _correctCount++;
      } else {
        _incorrectCount++;
      }
    });

    await ProgressService.registerPracticeAnswer(
      isCorrect: isCorrect,
    );

    // Refuerzo multimodal bilingüe accesible (RF-08)
    if (isCorrect) {
      await _ttsService.speakSpanish('¡Correcto! Well done.');
    } else {
      if (_selectedMode == 'Completar la frase') {
        await _ttsService.speakSpanish('Inténtalo de nuevo. La palabra correcta era ${_currentWord.wordEn}.');
      } else {
        await _ttsService.speakSpanish('Inténtalo de nuevo. ${_currentWord.wordEn} significa ${_currentWord.wordEs}.');
      }
    }
  }

  void _nextQuestion() {
    HapticService.selection();
    final isLastQuestion =
        _currentQuestionIndex + 1 >= _selectedQuestionLimit;

    if (isLastQuestion) {
      setState(() {
        _currentStep = PracticeStep.setup;
      });

      _showFinalResult();
      return;
    }

    setState(() {
      _currentQuestionIndex++;
      _generateQuestion();
    });
  }

  Future<bool?> _showExitConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Deseas salir de la práctica?'),
        content: const Text('Se perderá el avance de esta sesión.'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar practicando'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              minimumSize: const Size(48, 48),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFinalResult() async {
    _ttsService.speakSpanish('Práctica finalizada. Excelente esfuerzo.');

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Práctica finalizada'),
          content: Text(
            'Respuestas correctas: $_correctCount\n'
            'Respuestas incorrectas: $_incorrectCount\n'
            'Total: $_selectedQuestionLimit preguntas',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentStep = PracticeStep.modeSelection;
                  _selectedMode = null;
                });
              },
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentStep = PracticeStep.setup;
                });
              },
              child: const Text('Nueva práctica'),
            ),
          ],
        );
      },
    );
  }

  Color? _optionColor(GlossaryWord word) {
    if (!_answered) return null;

    if (word.id == _currentWord.id) {
      return Colors.green.shade100;
    }

    if (word.id == _selectedWordId && _wasCorrect == false) {
      return Colors.red.shade100;
    }

    return null;
  }

  IconData? _optionIcon(GlossaryWord word) {
    if (!_answered) return null;

    if (word.id == _currentWord.id) {
      return Icons.check_circle_rounded;
    }

    if (word.id == _selectedWordId && _wasCorrect == false) {
      return Icons.cancel_rounded;
    }

    return null;
  }

  String _feedbackText() {
    if (!_answered) {
      return _selectedMode == 'Completar la frase'
          ? 'Lee la oración con el espacio en blanco y selecciona la palabra correcta.'
          : 'Escucha la palabra en inglés y selecciona el significado correcto.';
    }

    if (_wasCorrect == true) {
      return '¡Correcto! Well done.';
    }

    if (_selectedMode == 'Completar la frase') {
      return 'Inténtalo de nuevo. La respuesta correcta era ${_currentWord.wordEn}.';
    }
    return 'Inténtalo de nuevo. ${_currentWord.wordEn} significa ${_currentWord.wordEs}.';
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case PracticeStep.modeSelection:
        return _buildModeSelectionScreen();
      case PracticeStep.setup:
        return _buildSetupScreen();
      case PracticeStep.playing:
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final exit = await _showExitConfirmation();
            if (exit == true && mounted) {
              _ttsService.stop();
              setState(() {
                _currentStep = PracticeStep.setup;
              });
            }
          },
          child: _buildPracticeScreen(),
        );
    }
  }

  Widget _buildModeSelectionScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prácticas guiadas'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Modalidades de práctica',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Elige cómo deseas entrenar tu oído y consolidar tu vocabulario en inglés A1.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              // Modalidad 1: Asociación auditiva (50% de la pantalla)
              Expanded(
                child: Semantics(
                  button: true,
                  label:
                      'Asociación auditiva. Escucha con atención la palabra en inglés y selecciona el significado correcto. Toca dos veces para configurar esta práctica.',
                  child: Card(
                    color: AppTheme.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _chooseMode('Asociación auditiva'),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.hearing_rounded,
                                color: Color(0xFF10B981),
                                size: 38,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Asociación auditiva',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Escucha con atención la palabra en inglés y selecciona el significado correcto.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Modalidad 2: Completar la frase (50% de la pantalla)
              Expanded(
                child: Semantics(
                  button: true,
                  label:
                      'Completar la frase. Escucha la oración y elige la palabra que falta. Toca dos veces para configurar esta práctica.',
                  child: Card(
                    color: AppTheme.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _chooseMode('Completar la frase'),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit_note_rounded,
                                color: Color(0xFF6366F1),
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Completar la frase',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Escucha la oración contextual y elige la palabra en inglés que falta.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupScreen() {
    final modeName = _selectedMode ?? 'Práctica guiada';
    final isFillBlank = _selectedMode == 'Completar la frase';

    return Scaffold(
      appBar: AppBar(
        title: Text(modeName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver a modalidades',
          onPressed: _backToModeSelection,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isFillBlank ? Icons.edit_note_rounded : Icons.hearing_rounded,
                      color: AppTheme.primary,
                      size: 42,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Configurar: $modeName',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isFillBlank
                          ? 'Escucharás una oración en inglés con un espacio en blanco y deberás elegir la palabra que la completa.'
                          : 'Escucharás una palabra en inglés y deberás seleccionar su traducción o significado correcto en español.',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        HapticService.selection();
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    DropdownButtonFormField<int>(
                      value: _selectedQuestionLimit,
                      decoration: InputDecoration(
                        labelText: 'Número de preguntas',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      items: _questionLimits
                          .map(
                            (limit) => DropdownMenuItem(
                              value: limit,
                              child: Text('$limit preguntas'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        HapticService.selection();
                        setState(() {
                          _selectedQuestionLimit = value;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    Semantics(
                      label: 'Iniciar práctica de $modeName',
                      button: true,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: _startPractice,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text(
                          'Iniciar práctica',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _backToModeSelection,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Elegir otra modalidad'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeScreen() {
    final currentNumber = _currentQuestionIndex + 1;
    final isFillBlank = _selectedMode == 'Completar la frase';

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedMode ?? 'Práctica'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pregunta $currentNumber de $_selectedQuestionLimit',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Icon(
                      isFillBlank ? Icons.edit_note_rounded : Icons.hearing_rounded,
                      color: AppTheme.primary,
                      size: 42,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _selectedMode ?? 'Práctica',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _feedbackText(),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (isFillBlank) ...[
                      Semantics(
                        label: 'Oración para completar: $_sentenceWithBlank',
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            _sentenceWithBlank,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pista en español: "${_currentWord.exampleEs}"',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    Semantics(
                      label: isFillBlank
                          ? 'Escuchar oración con espacio en blanco'
                          : 'Escuchar palabra en inglés ${_currentWord.wordEn}',
                      button: true,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: _playQuestionAudio,
                        icon: const Icon(Icons.volume_up_rounded),
                        label: Text(
                          isFillBlank ? 'Escuchar oración' : 'Escuchar palabra',
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Semantics(
                      label: isFillBlank
                          ? 'Escuchar oración lentamente'
                          : 'Escuchar palabra en inglés lentamente ${_currentWord.wordEn}',
                      button: true,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: _playQuestionAudioSlow,
                        icon: const Icon(Icons.slow_motion_video_rounded),
                        label: const Text('Escuchar lento'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              isFillBlank
                  ? 'Selecciona la palabra que completa la oración:'
                  : 'Selecciona el significado correcto:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            ..._options.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final word = entry.value;
                final icon = _optionIcon(word);

                final displayText = isFillBlank ? word.wordEn : word.wordEs;
                final subtitleText = isFillBlank ? word.wordEs : word.category;

                String semanticLabel = 'Opción ${index + 1}: $displayText';
                if (_answered) {
                  if (word.id == _currentWord.id) {
                    semanticLabel += ', respuesta correcta';
                  } else if (word.id == _selectedWordId) {
                    semanticLabel += ', respuesta incorrecta seleccionada';
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    label: semanticLabel,
                    button: true,
                    excludeSemantics: true,
                    child: Card(
                      color: _optionColor(word),
                      child: ListTile(
                        leading: icon == null
                            ? const Icon(Icons.circle_outlined)
                            : Icon(
                                icon,
                                color: word.id == _currentWord.id
                                    ? Colors.green
                                    : Colors.red,
                              ),
                        title: Text(
                          displayText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(subtitleText),
                        onTap: () => _selectAnswer(word),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            if (_answered)
              Semantics(
                label: 'Siguiente pregunta',
                button: true,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text(
                    'Siguiente pregunta',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}