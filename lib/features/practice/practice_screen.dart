import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/encouragement_service.dart';
import '../../services/haptic_service.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../glossary/glossary_data.dart';
import '../glossary/glossary_word.dart';
import 'riddle_practice_screen.dart';
import 'true_false_practice_screen.dart';

class _A1FillBlankTemplate {
  final String sentence;
  final String hint;

  const _A1FillBlankTemplate({required this.sentence, required this.hint});
}

/// Banco pedagógico de oraciones simplificadas a nivel MCER A1 (presente simple, estructuras directas y vocabulario cotidiano).
const Map<String, _A1FillBlankTemplate> _a1FillBlankTemplates = {
  'pen': _A1FillBlankTemplate(
    sentence: 'I write in my notebook with a blue _____.',
    hint: 'Escribo en mi cuaderno con un bolígrafo azul.',
  ),
  'board': _A1FillBlankTemplate(
    sentence: 'The teacher writes new words on the _____.',
    hint: 'El profesor escribe palabras nuevas en el tablero.',
  ),
  'bottle': _A1FillBlankTemplate(
    sentence: 'I drink cold water from my _____.',
    hint: 'Bebo agua fría de mi botella.',
  ),
  'apple': _A1FillBlankTemplate(
    sentence: 'The sweet red fruit is an _____.',
    hint: 'La fruta roja y dulce es una manzana.',
  ),
  'chair': _A1FillBlankTemplate(
    sentence: 'Please sit down on the comfortable _____.',
    hint: 'Por favor siéntate en la silla cómoda.',
  ),
  'book': _A1FillBlankTemplate(
    sentence: 'I read an interesting _____ in English.',
    hint: 'Leo un libro interesante en inglés.',
  ),
  'table': _A1FillBlankTemplate(
    sentence: 'We eat lunch together at the kitchen _____.',
    hint: 'Almorzamos juntos en la mesa de la cocina.',
  ),
  'door': _A1FillBlankTemplate(
    sentence: 'Please close the front _____ when you enter.',
    hint: 'Por favor cierra la puerta principal cuando entres.',
  ),
  'window': _A1FillBlankTemplate(
    sentence: 'Open the big _____ to let the sun in.',
    hint: 'Abre la ventana grande para que entre el sol.',
  ),
  'backpack': _A1FillBlankTemplate(
    sentence: 'I carry my books and pencils in my _____.',
    hint: 'Llevo mis libros y lápices en mi mochila.',
  ),
  'pencil': _A1FillBlankTemplate(
    sentence: 'I draw a house with my yellow _____.',
    hint: 'Dibujo una casa con mi lápiz amarillo.',
  ),
  'notebook': _A1FillBlankTemplate(
    sentence: 'I write my class notes in my new _____.',
    hint: 'Escribo mis notas de clase en mi nuevo cuaderno.',
  ),
  'eraser': _A1FillBlankTemplate(
    sentence: 'I use an _____ when I make a mistake.',
    hint: 'Uso un borrador cuando cometo un error.',
  ),
  'desk': _A1FillBlankTemplate(
    sentence: 'My computer and books are on my study _____.',
    hint: 'Mi computadora y mis libros están en mi escritorio de estudio.',
  ),
  'clock': _A1FillBlankTemplate(
    sentence: 'The _____ on the wall shows the time.',
    hint: 'El reloj en la pared muestra la hora.',
  ),
  'glasses': _A1FillBlankTemplate(
    sentence: 'I wear my black _____ to read clearly.',
    hint: 'Uso mis gafas negras para leer con claridad.',
  ),
  'computer': _A1FillBlankTemplate(
    sentence: 'I study my English lessons on my _____.',
    hint: 'Estudio mis lecciones de inglés en mi computadora.',
  ),
  'phone': _A1FillBlankTemplate(
    sentence: 'I call my family every day with my _____.',
    hint: 'Llamo a mi familia todos los días con mi teléfono.',
  ),
  'cup': _A1FillBlankTemplate(
    sentence: 'I drink hot tea in a small _____.',
    hint: 'Bebo té caliente en una taza pequeña.',
  ),
  'spoon': _A1FillBlankTemplate(
    sentence: 'I eat hot vegetable soup with a _____.',
    hint: 'Como sopa caliente de verduras con una cuchara.',
  ),
  'fork': _A1FillBlankTemplate(
    sentence: 'I use a _____ to eat my fresh salad.',
    hint: 'Uso un tenedor para comer mi ensalada fresca.',
  ),
  'plate': _A1FillBlankTemplate(
    sentence: 'The warm food is served on a clean _____.',
    hint: 'La comida tibia se sirve en un plato limpio.',
  ),
  'keys': _A1FillBlankTemplate(
    sentence: 'I open the front door with my metal _____.',
    hint: 'Abro la puerta principal con mis llaves de metal.',
  ),
  'key': _A1FillBlankTemplate(
    sentence: 'I open the house door with this _____.',
    hint: 'Abro la puerta de la casa con esta llave.',
  ),
  'shoes': _A1FillBlankTemplate(
    sentence: 'I put on my black _____ to go for a walk.',
    hint: 'Me pongo mis zapatos negros para salir a caminar.',
  ),
  'shoe': _A1FillBlankTemplate(
    sentence: 'I put a comfortable _____ on my foot.',
    hint: 'Me pongo un zapato cómodo en el pie.',
  ),
  'shirt': _A1FillBlankTemplate(
    sentence: 'He wears a clean white _____ to school.',
    hint: 'Él usa una camisa blanca limpia para ir a la escuela.',
  ),
  'pants': _A1FillBlankTemplate(
    sentence: 'I wear blue _____ and a white shirt.',
    hint: 'Uso pantalones azules y una camisa blanca.',
  ),
  'hat': _A1FillBlankTemplate(
    sentence: 'I wear a warm _____ on my head in the sun.',
    hint: 'Uso un sombrero protector en mi cabeza bajo el sol.',
  ),
  'watch': _A1FillBlankTemplate(
    sentence: 'I look at my wrist _____ to see what time it is.',
    hint: 'Miro mi reloj de pulsera para ver qué hora es.',
  ),
  'wallet': _A1FillBlankTemplate(
    sentence: 'I keep my money inside my leather _____.',
    hint: 'Guardo mi dinero dentro de mi billetera.',
  ),
  'umbrella': _A1FillBlankTemplate(
    sentence: 'I take an _____ with me when it rains.',
    hint: 'Llevo un paraguas conmigo cuando llueve.',
  ),
  'water': _A1FillBlankTemplate(
    sentence: 'I drink a fresh glass of _____ every morning.',
    hint: 'Bebo un vaso de agua fresca cada mañana.',
  ),
  'bread': _A1FillBlankTemplate(
    sentence: 'We eat warm _____ with butter for breakfast.',
    hint: 'Comemos pan caliente con mantequilla en el desayuno.',
  ),
  'milk': _A1FillBlankTemplate(
    sentence: 'I drink a cold glass of _____ with cookies.',
    hint: 'Bebo un vaso de leche fría con galletas.',
  ),
  'bed': _A1FillBlankTemplate(
    sentence: 'I sleep in my comfortable _____ at night.',
    hint: 'Duermo en mi cama cómoda por la noche.',
  ),
  'car': _A1FillBlankTemplate(
    sentence: 'My father drives his red _____ to work.',
    hint: 'Mi padre conduce su carro rojo al trabajo.',
  ),
  'bus': _A1FillBlankTemplate(
    sentence: 'I take the yellow _____ to go to school.',
    hint: 'Tomo el autobús amarillo para ir a la escuela.',
  ),
  'bicycle': _A1FillBlankTemplate(
    sentence: 'I ride my new _____ in the green park.',
    hint: 'Monto mi nueva bicicleta en el parque verde.',
  ),
  'dog': _A1FillBlankTemplate(
    sentence: 'The friendly _____ runs and plays in the yard.',
    hint: 'El perro amigable corre y juega en el patio.',
  ),
  'cat': _A1FillBlankTemplate(
    sentence: 'The little _____ sleeps peacefully on the sofa.',
    hint: 'El pequeño gato duerme plácidamente en el sofá.',
  ),
  'bird': _A1FillBlankTemplate(
    sentence: 'The small _____ sings high in the tree.',
    hint: 'El pequeño pájaro canta en lo alto del árbol.',
  ),
  'cow': _A1FillBlankTemplate(
    sentence: 'The big _____ eats green grass on the farm.',
    hint: 'La vaca grande come pasto verde en la granja.',
  ),
  'duck': _A1FillBlankTemplate(
    sentence: 'The yellow _____ swims happily in the lake.',
    hint: 'El pato amarillo nada alegremente en el lago.',
  ),
  'fish': _A1FillBlankTemplate(
    sentence: 'The little blue _____ swims in the water.',
    hint: 'El pequeño pez azul nada en el agua.',
  ),
  'horse': _A1FillBlankTemplate(
    sentence: 'The brown _____ runs fast in the field.',
    hint: 'El caballo marrón corre rápido en el campo.',
  ),
  'lion': _A1FillBlankTemplate(
    sentence: 'The strong _____ is the king of the animals.',
    hint: 'El león fuerte es el rey de los animales.',
  ),
  'rabbit': _A1FillBlankTemplate(
    sentence: 'The white _____ loves to eat fresh carrots.',
    hint: 'Al conejo blanco le encanta comer zanahorias frescas.',
  ),
  'turtle': _A1FillBlankTemplate(
    sentence: 'The green _____ walks very slowly on the sand.',
    hint: 'La tortuga verde camina muy despacio sobre la arena.',
  ),
};

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
  String _currentEncouragement = '¡Excelente trabajo! Well done!';

  int _currentQuestionIndex = 0;
  int _correctCount = 0;
  int _incorrectCount = 0;

  String? _selectedWordId;

  late List<GlossaryWord> _practicePool;
  List<GlossaryWord> _roundQuestions = [];
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
      if (widget.initialMode == 'Verdadero o Falso') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrueFalsePracticeScreen()),
          );
        });
      } else if (widget.initialMode == 'Adivina por la descripción') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RiddlePracticeScreen()),
          );
        });
      } else {
        _selectedMode = widget.initialMode;
        _currentStep = PracticeStep.setup;
      }
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _chooseMode(String mode) {
    HapticService.buttonPress();
    if (mode == 'Verdadero o Falso') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrueFalsePracticeScreen()),
      );
      return;
    }
    if (mode == 'Adivina por la descripción') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RiddlePracticeScreen()),
      );
      return;
    }
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
    final count = min(_selectedQuestionLimit, filteredWords.length);

    setState(() {
      _practicePool = filteredWords;
      // Muestreo sin reemplazo: garantiza que ninguna palabra/frase se repita en la misma ronda
      _roundQuestions = filteredWords.take(count).toList();
      _currentStep = PracticeStep.playing;
      _currentQuestionIndex = 0;
      _correctCount = 0;
      _incorrectCount = 0;
      _generateQuestion();
    });
  }

  void _generateQuestion() {
    _currentWord = _roundQuestions[_currentQuestionIndex];

    final wrongCount = _selectedMode == 'Completar la frase' ? 2 : 3;
    final candidates = _practicePool
        .where((word) => word.id != _currentWord.id)
        .toList();
    candidates.shuffle(_random);
    final wrongOptions = candidates.take(wrongCount).toList();

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
    final key = _currentWord.wordEn.trim().toLowerCase();
    if (_a1FillBlankTemplates.containsKey(key)) {
      return _a1FillBlankTemplates[key]!.sentence;
    }

    final en = _currentWord.exampleEn;
    final pattern = RegExp(RegExp.escape(_currentWord.wordEn), caseSensitive: false);
    if (pattern.hasMatch(en)) {
      return en.replaceFirst(pattern, '_____');
    }
    return 'The _____ is on the table.';
  }

  String get _sentenceHint {
    final key = _currentWord.wordEn.trim().toLowerCase();
    if (_a1FillBlankTemplates.containsKey(key)) {
      return _a1FillBlankTemplates[key]!.hint;
    }
    return _currentWord.exampleEs;
  }

  Future<void> _selectAnswer(GlossaryWord selectedWord) async {
    if (_answered) return;

    final isCorrect = selectedWord.id == _currentWord.id;

    if (isCorrect) {
      _currentEncouragement = EncouragementService.getRandomEncouragement();
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

    // Refuerzo multimodal bilingüe accesible (RF-08) con frases alentadoras aleatorias
    if (isCorrect) {
      await _ttsService.speakSpanish(_currentEncouragement);
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
        _currentQuestionIndex + 1 >= _roundQuestions.length;

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
        title: const Text('¿Deseas hacer una pausa?'),
        content: const Text('Si sales ahora, no se guardará el avance de esta ronda. ¿Quieres seguir practicando?'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () {
              HapticService.selection();
              Navigator.pop(ctx, false);
            },
            child: const Text('Seguir aprendiendo'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              minimumSize: const Size(48, 48),
            ),
            onPressed: () {
              HapticService.buttonPress();
              Navigator.pop(ctx, true);
            },
            child: const Text('Pausar y salir'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFinalResult() async {
    final int total = _roundQuestions.length;
    await HapticService.success();
    await _ttsService.playVictorySound();
    await _ttsService.speakPracticeSummary(
      totalPreguntas: total,
      totalAciertos: _correctCount,
      totalFallos: _incorrectCount,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¡Gran esfuerzo! Práctica completada'),
          content: Text(
            '¡Felicitaciones por practicar!\n\n'
            'Respuestas correctas: $_correctCount\n'
            'Preguntas para repasar: $_incorrectCount\n'
            'Total completado: ${_roundQuestions.length} preguntas',
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticService.selection();
                Navigator.pop(context);
                setState(() {
                  _currentStep = PracticeStep.modeSelection;
                  _selectedMode = null;
                });
              },
              child: const Text('Volver al menú'),
            ),
            FilledButton(
              onPressed: () {
                HapticService.buttonPress();
                Navigator.pop(context);
                setState(() {
                  _currentStep = PracticeStep.setup;
                });
              },
              child: const Text('¡Practicar de nuevo!'),
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
      return _currentEncouragement;
    }

    if (_selectedMode == 'Completar la frase') {
      return '¡Casi! Ánimo, la respuesta correcta era "${_currentWord.wordEn}". ¡Sigamos practicando!';
    }
    return '¡Buen intento! "${_currentWord.wordEn}" significa "${_currentWord.wordEs}". ¡Sigamos adelante!';
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text(
              'Modalidades de práctica',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Elige cómo deseas entrenar tu oído y consolidar tu vocabulario en inglés A1.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),

            // Modalidad 1: Asociación auditiva
            _buildModeCard(
              title: 'Asociación auditiva',
              description: 'Escucha con atención la palabra en inglés y selecciona el significado correcto.',
              icon: Icons.hearing_rounded,
              accentColor: const Color(0xFF10B981),
              semanticHint: 'Toca dos veces para configurar esta práctica.',
              onTap: () => _chooseMode('Asociación auditiva'),
            ),

            const SizedBox(height: 16),

            // Modalidad 2: Completar la frase
            _buildModeCard(
              title: 'Completar la frase',
              description: 'Escucha la oración contextual A1 y elige la palabra en inglés que falta.',
              icon: Icons.edit_note_rounded,
              accentColor: const Color(0xFF6366F1),
              semanticHint: 'Toca dos veces para configurar esta práctica.',
              onTap: () => _chooseMode('Completar la frase'),
            ),

            const SizedBox(height: 16),

            // Modalidad 3: Verdadero o Falso
            _buildModeCard(
              title: 'Verdadero o Falso',
              description: 'Evalúa la asociación bilingüe entre el término en inglés y su significado.',
              icon: Icons.check_circle_outline_rounded,
              accentColor: const Color(0xFFD97706),
              semanticHint: 'Toca dos veces para iniciar este desafío.',
              onTap: () => _chooseMode('Verdadero o Falso'),
            ),

            const SizedBox(height: 16),

            // Modalidad 4: Adivina por la descripción
            _buildModeCard(
              title: 'Adivina por la descripción',
              description: 'Escucha pistas funcionales en español y adivina el objeto en inglés.',
              icon: Icons.lightbulb_rounded,
              accentColor: const Color(0xFF8B5CF6),
              semanticHint: 'Toca dos veces para iniciar este desafío.',
              onTap: () => _chooseMode('Adivina por la descripción'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required String semanticHint,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Semantics(
      button: true,
      label: '$title. $description. $semanticHint',
      child: Card(
        color: AppTheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticService.buttonPress();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: accentColor,
                ),
              ],
            ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: _startPractice,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Flexible(
                          child: Text(
                            'Iniciar práctica',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: _backToModeSelection,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Flexible(
                        child: Text(
                          'Elegir otra modalidad',
                          textAlign: TextAlign.center,
                        ),
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
                      'Pregunta $currentNumber de ${_roundQuestions.length}',
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
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderSubtle, width: 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Pista en español: "$_sentenceHint"',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Semantics(
                              button: true,
                              label: 'Escuchar pista en español: $_sentenceHint',
                              hint: 'Toca dos veces para escuchar la pista en español en voz alta',
                              child: IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                                  foregroundColor: AppTheme.primary,
                                  minimumSize: const Size(48, 48),
                                ),
                                icon: const Icon(Icons.volume_up_rounded, size: 24),
                                tooltip: 'Escuchar pista en español',
                                onPressed: () async {
                                  await HapticService.buttonPress();
                                  await _ttsService.speakSpanish('Pista: $_sentenceHint');
                                },
                              ),
                            ),
                          ],
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: _playQuestionAudio,
                        icon: const Icon(Icons.volume_up_rounded),
                        label: Flexible(
                          child: Text(
                            isFillBlank ? 'Escuchar oración' : 'Escuchar palabra',
                            textAlign: TextAlign.center,
                          ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: _playQuestionAudioSlow,
                        icon: const Icon(Icons.slow_motion_video_rounded),
                        label: const Flexible(
                          child: Text(
                            'Escuchar lento',
                            textAlign: TextAlign.center,
                          ),
                        ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Flexible(
                    child: Text(
                      'Siguiente pregunta',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}