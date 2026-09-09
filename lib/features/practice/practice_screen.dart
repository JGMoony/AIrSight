import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/services/progress_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../glossary/glossary_data.dart';
import '../glossary/glossary_word.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final TtsService _ttsService = TtsService();
  final Random _random = Random();

  final List<int> _questionLimits = [5, 10, 15, 20];

  late List<String> _categories;

  String _selectedCategory = 'Aleatorio';
  int _selectedQuestionLimit = 5;

  bool _practiceStarted = false;
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
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _startPractice() {
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
      _practiceStarted = true;
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

    final wrongOptions = words
        .where((word) => word.id != _currentWord.id)
        .take(3)
        .toList();

    _options = [_currentWord, ...wrongOptions];
    _options.shuffle(_random);

    _answered = false;
    _wasCorrect = null;
    _selectedWordId = null;
  }

  Future<void> _playQuestionAudio() async {
    await _ttsService.speakEnglish(_currentWord.wordEn);
    await ProgressService.registerAudioPlay();
  }

  Future<void> _playQuestionAudioSlow() async {
    await _ttsService.speakEnglishSlow(_currentWord.wordEn);
    await ProgressService.registerAudioPlay();
  }

  Future<void> _selectAnswer(GlossaryWord selectedWord) async {
    if (_answered) return;

    final isCorrect = selectedWord.id == _currentWord.id;

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

    if (isCorrect) {
      await _ttsService.speakEnglish('Correct');
    } else {
      await _ttsService.speakEnglish(
        'Incorrect. The correct answer is ${_currentWord.wordEn}.',
      );
    }
  }

  void _nextQuestion() {
    final isLastQuestion =
        _currentQuestionIndex + 1 >= _selectedQuestionLimit;

    if (isLastQuestion) {
      setState(() {
        _practiceStarted = false;
      });

      _showFinalResult();
      return;
    }

    setState(() {
      _currentQuestionIndex++;
      _generateQuestion();
    });
  }

  Future<void> _showFinalResult() async {
    await _ttsService.speakEnglish('Practice completed');

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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _practiceStarted = false;
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
      return 'Escucha la palabra en inglés y selecciona la opción correcta.';
    }

    if (_wasCorrect == true) {
      return 'Correcto.';
    }

    return 'Incorrecto. La respuesta correcta era ${_currentWord.wordEn}.';
  }

  @override
  Widget build(BuildContext context) {
    if (!_practiceStarted) {
      return _buildSetupScreen();
    }

    return _buildPracticeScreen();
  }

  Widget _buildSetupScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Práctica'),
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
                    const Icon(
                      Icons.quiz_rounded,
                      color: AppTheme.primary,
                      size: 42,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Configurar práctica',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Escoge una categoría y la cantidad de preguntas que deseas responder.',
                      style: TextStyle(
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

                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

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

                        setState(() {
                          _selectedQuestionLimit = value;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    Semantics(
                      label: 'Iniciar práctica',
                      button: true,
                      child: FilledButton.icon(
                        onPressed: _startPractice,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Iniciar práctica'),
                      ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Práctica'),
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
                    const Icon(
                      Icons.hearing_rounded,
                      color: AppTheme.primary,
                      size: 42,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Escucha y responde',
                      style: TextStyle(
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

                    Semantics(
                      label:
                          'Escuchar palabra en inglés ${_currentWord.wordEn}',
                      button: true,
                      child: ElevatedButton.icon(
                        onPressed: _playQuestionAudio,
                        icon: const Icon(Icons.volume_up_rounded),
                        label: const Text('Escuchar palabra'),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Semantics(
                      label:
                          'Escuchar palabra en inglés lentamente ${_currentWord.wordEn}',
                      button: true,
                      child: OutlinedButton.icon(
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

            const Text(
              'Selecciona la palabra correcta en inglés',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            ..._options.map(
              (word) {
                final icon = _optionIcon(word);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    label: 'Opción ${word.wordEn}',
                    button: true,
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
                          word.wordEn,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(word.category),
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
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Siguiente pregunta'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}