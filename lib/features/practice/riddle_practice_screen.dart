import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../core/theme/app_theme.dart';
import '../../services/encouragement_service.dart';
import '../../services/haptic_service.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';

/// Modelo inmutable de pregunta para "Adivina por la Descripción".
/// Vincula de forma estricta la pista en español con la palabra correcta en inglés y sus distractores,
/// impidiendo desincronizaciones entre el catálogo y las opciones barajadas.
class RiddleQuestion {
  final String id;
  final String clueEs;        // Pista en español unívoca y elemental (A1)
  final String correctWordEn; // Palabra correcta en inglés
  final String correctWordEs; // Traducción en español
  final List<String> options; // Las 3 opciones barajadas (1 correcta + 2 distractores)

  RiddleQuestion({
    required this.id,
    required this.clueEs,
    required this.correctWordEn,
    required this.correctWordEs,
    required List<String> distractorsEn,
  }) : options = ([correctWordEn, ...distractorsEn]..shuffle());
}

class _A1RiddleDefinition {
  final String id;
  final String clueEs;
  final String correctWordEn;
  final String correctWordEs;
  final List<String> distractorsEn;

  const _A1RiddleDefinition({
    required this.id,
    required this.clueEs,
    required this.correctWordEn,
    required this.correctWordEs,
    required this.distractorsEn,
  });
}

/// Banco de pistas funcionales simples y directas en español para objetos cotidianos A1
const List<_A1RiddleDefinition> _a1RiddleDefinitions = [
  _A1RiddleDefinition(
    id: 'r_computer',
    clueEs: 'Tiene una pantalla, teclado y mouse. Puedes usarlo para estudiar o navegar en internet.',
    correctWordEn: 'Computer',
    correctWordEs: 'computadora',
    distractorsEn: ['Phone', 'Clock'],
  ),
  _A1RiddleDefinition(
    id: 'r_phone',
    clueEs: 'Es un dispositivo pequeño que usas en la mano para llamar, enviar mensajes y escuchar música.',
    correctWordEn: 'Phone',
    correctWordEs: 'teléfono',
    distractorsEn: ['Book', 'Wallet'],
  ),
  _A1RiddleDefinition(
    id: 'r_pen',
    clueEs: 'Es un útil escolar con tinta que usas para escribir notas en tu cuaderno.',
    correctWordEn: 'Pen',
    correctWordEs: 'bolígrafo',
    distractorsEn: ['Eraser', 'Ruler'],
  ),
  _A1RiddleDefinition(
    id: 'r_pencil',
    clueEs: 'Es de madera con punta de grafito, sirve para escribir o dibujar y puedes borrar sus trazos.',
    correctWordEn: 'Pencil',
    correctWordEs: 'lápiz',
    distractorsEn: ['Chair', 'Desk'],
  ),
  _A1RiddleDefinition(
    id: 'r_book',
    clueEs: 'Tiene muchas páginas de papel encuadernadas con historias o lecciones para leer.',
    correctWordEn: 'Book',
    correctWordEs: 'libro',
    distractorsEn: ['Notebook', 'Bottle'],
  ),
  _A1RiddleDefinition(
    id: 'r_notebook',
    clueEs: 'Cuaderno con hojas en blanco o con líneas donde tomas notas en tus clases.',
    correctWordEn: 'Notebook',
    correctWordEs: 'cuaderno',
    distractorsEn: ['Table', 'Door'],
  ),
  _A1RiddleDefinition(
    id: 'r_bottle',
    clueEs: 'Es un recipiente con tapa que llevas para beber agua fresca cuando tienes sed.',
    correctWordEn: 'Bottle',
    correctWordEs: 'botella',
    distractorsEn: ['Cup', 'Plate'],
  ),
  _A1RiddleDefinition(
    id: 'r_chair',
    clueEs: 'Mueble con cuatro patas y respaldo donde te sientas a descansar, comer o estudiar.',
    correctWordEn: 'Chair',
    correctWordEs: 'silla',
    distractorsEn: ['Bed', 'Desk'],
  ),
  _A1RiddleDefinition(
    id: 'r_desk',
    clueEs: 'Mesa de trabajo o estudio donde apoyas tus libros, cuadernos o computadora.',
    correctWordEn: 'Desk',
    correctWordEs: 'escritorio',
    distractorsEn: ['Door', 'Window'],
  ),
  _A1RiddleDefinition(
    id: 'r_board',
    clueEs: 'Superficie grande en el salón de clases donde el profesor escribe con marcador o tiza.',
    correctWordEn: 'Board',
    correctWordEs: 'pizarra',
    distractorsEn: ['Backpack', 'Hat'],
  ),
  _A1RiddleDefinition(
    id: 'r_backpack',
    clueEs: 'Bolsa con correas que llevas en la espalda para transportar todos tus útiles escolares.',
    correctWordEn: 'Backpack',
    correctWordEs: 'mochila',
    distractorsEn: ['Shoes', 'Shirt'],
  ),
  _A1RiddleDefinition(
    id: 'r_eraser',
    clueEs: 'Objeto de goma suave que usas para borrar las marcas de lápiz en el papel.',
    correctWordEn: 'Eraser',
    correctWordEs: 'borrador',
    distractorsEn: ['Pen', 'Pencil'],
  ),
  _A1RiddleDefinition(
    id: 'r_clock',
    clueEs: 'Aparato que está en la pared o en tu muñeca y te indica la hora exacta.',
    correctWordEn: 'Clock',
    correctWordEs: 'reloj',
    distractorsEn: ['Watch', 'Glasses'],
  ),
  _A1RiddleDefinition(
    id: 'r_apple',
    clueEs: 'Fruta redonda y crujiente, normalmente roja o verde, muy dulce y saludable.',
    correctWordEn: 'Apple',
    correctWordEs: 'manzana',
    distractorsEn: ['Bread', 'Milk'],
  ),
  _A1RiddleDefinition(
    id: 'r_water',
    clueEs: 'Líquido transparente y natural esencial para la vida que bebes para hidratarte.',
    correctWordEn: 'Water',
    correctWordEs: 'agua',
    distractorsEn: ['Milk', 'Coffee'],
  ),
  _A1RiddleDefinition(
    id: 'r_bread',
    clueEs: 'Alimento horneado hecho con harina y levadura que comes al desayuno.',
    correctWordEn: 'Bread',
    correctWordEs: 'pan',
    distractorsEn: ['Apple', 'Water'],
  ),
  _A1RiddleDefinition(
    id: 'r_milk',
    clueEs: 'Bebida blanca, nutritiva y fría que proviene de la vaca.',
    correctWordEn: 'Milk',
    correctWordEs: 'leche',
    distractorsEn: ['Water', 'Tea'],
  ),
  _A1RiddleDefinition(
    id: 'r_bed',
    clueEs: 'Mueble con colchón suave, almohada y cobijas donde duermes por las noches.',
    correctWordEn: 'Bed',
    correctWordEs: 'cama',
    distractorsEn: ['Chair', 'Table'],
  ),
  _A1RiddleDefinition(
    id: 'r_door',
    clueEs: 'Estructura que abres y cierras con una manija para entrar o salir de una habitación.',
    correctWordEn: 'Door',
    correctWordEs: 'puerta',
    distractorsEn: ['Window', 'Wall'],
  ),
  _A1RiddleDefinition(
    id: 'r_window',
    clueEs: 'Abertura de vidrio en la pared que deja entrar la luz del sol y el aire fresco.',
    correctWordEn: 'Window',
    correctWordEs: 'ventana',
    distractorsEn: ['Door', 'Board'],
  ),
  _A1RiddleDefinition(
    id: 'r_shoes',
    clueEs: 'Prendas que calzas en los pies para caminar cómodo y protegerte del suelo.',
    correctWordEn: 'Shoes',
    correctWordEs: 'zapatos',
    distractorsEn: ['Pants', 'Hat'],
  ),
  _A1RiddleDefinition(
    id: 'r_shirt',
    clueEs: 'Prenda de vestir con cuello o botones que cubre el pecho y la espalda.',
    correctWordEn: 'Shirt',
    correctWordEs: 'camisa',
    distractorsEn: ['Shoes', 'Backpack'],
  ),
  _A1RiddleDefinition(
    id: 'r_dog',
    clueEs: 'Mascota fiel que ladra alegremente y cuida la casa.',
    correctWordEn: 'Dog',
    correctWordEs: 'perro',
    distractorsEn: ['Cat', 'Bird'],
  ),
  _A1RiddleDefinition(
    id: 'r_cat',
    clueEs: 'Mascota pequeña, suave y ágil que maúlla y ronronea cuando la acaricias.',
    correctWordEn: 'Cat',
    correctWordEs: 'gato',
    distractorsEn: ['Dog', 'Duck'],
  ),
  _A1RiddleDefinition(
    id: 'r_car',
    clueEs: 'Vehículo familiar con cuatro ruedas y motor en el que viajas por la calle.',
    correctWordEn: 'Car',
    correctWordEs: 'coche',
    distractorsEn: ['Bus', 'Bicycle'],
  ),
  _A1RiddleDefinition(
    id: 'r_bus',
    clueEs: 'Vehículo de transporte público muy grande que lleva a muchos pasajeros por la ciudad.',
    correctWordEn: 'Bus',
    correctWordEs: 'autobús',
    distractorsEn: ['Car', 'Bicycle'],
  ),
  _A1RiddleDefinition(
    id: 'r_bicycle',
    clueEs: 'Vehículo de dos ruedas que impulsas pedaleando con tus piernas al aire libre.',
    correctWordEn: 'Bicycle',
    correctWordEs: 'bicicleta',
    distractorsEn: ['Car', 'Bus'],
  ),
];

/// Pantalla de práctica gamificada: "Adivina por la Descripción" (Riddle Challenge) (WCAG 2.2 AA).
/// Verbaliza pistas funcionales en español sobre vocabulario A1 y aprovecha el 100% del espacio
/// disponible en pantalla para los botones de respuesta.
class RiddlePracticeScreen extends StatefulWidget {
  final int questionLimit;

  const RiddlePracticeScreen({
    super.key,
    this.questionLimit = 10,
  });

  @override
  State<RiddlePracticeScreen> createState() => _RiddlePracticeScreenState();
}

class _RiddlePracticeScreenState extends State<RiddlePracticeScreen> {
  final TtsService _ttsService = TtsService();
  final Random _random = Random();

  late final List<RiddleQuestion> _questions;
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
        _speakCurrentClue();
      }
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _buildQuestions() {
    final availableDefs = List<_A1RiddleDefinition>.from(_a1RiddleDefinitions)..shuffle(_random);
    final count = min(widget.questionLimit, availableDefs.length);
    final selected = availableDefs.take(count).toList();

    _questions = selected.map((d) {
      return RiddleQuestion(
        id: d.id,
        clueEs: d.clueEs,
        correctWordEn: d.correctWordEn,
        correctWordEs: d.correctWordEs,
        distractorsEn: d.distractorsEn,
      );
    }).toList();
  }

  RiddleQuestion get _currentQuestion => _questions[_currentIndex];

  Future<void> _speakCurrentClue() async {
    final q = _currentQuestion;
    final text = 'Adivina el objeto: ${q.clueEs} ¿Qué objeto es en inglés?';
    _announce(text);
    await _ttsService.speakSpanish(text);
  }

  Future<void> _handleOptionSelected(String option) async {
    if (_answered) return;

    final q = _currentQuestion;
    final isCorrect = (option.trim().toLowerCase() == q.correctWordEn.trim().toLowerCase());

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
      _announce('$_currentEncouragement ${q.correctWordEn} es el objeto correcto.');
      await _ttsService.speakSpanish('$_currentEncouragement ${q.correctWordEn} significa ${q.correctWordEs}.');
    } else {
      _announce('Incorrecto. La respuesta correcta era ${q.correctWordEn}.');
      await _ttsService.speakSpanish(
        '¡Buen intento! Recuerda que ${q.correctWordEn} significa ${q.correctWordEs}. ¡Sigamos aprendiendo!',
      );
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

    _speakCurrentClue();
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
          'Si sales ahora, no se guardará el avance de esta ronda de adivinanzas. ¿Quieres seguir practicando?',
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
        title: const Text('¡Gran esfuerzo! Adivinanzas completadas'),
        content: Text(
          '¡Felicitaciones por tu dedicación!\n\n'
          'Respuestas correctas: $_correctCount\n'
          'Preguntas para repasar: $_incorrectCount\n'
          'Total de adivinanzas: ${_questions.length}',
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
        appBar: AppBar(title: const Text('Adivina por la Descripción')),
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
          title: const Text('Adivina por la Descripción'),
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
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de Progreso Accesible
              Semantics(
                label: 'Adivinanza ${_currentIndex + 1} de $total',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Adivinanza ${_currentIndex + 1} de $total',
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
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tarjeta de la Pista (Clue Card compacta y accesible)
              Card(
                elevation: 0,
                color: AppTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.psychology_rounded,
                              color: Color(0xFF7C3AED),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Pista Funcional A1',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Texto de la pista
                      Semantics(
                        header: true,
                        label: 'Descripción del objeto: ${q.clueEs}',
                        child: Text(
                          '"${q.clueEs}"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Botón de audio
                      Semantics(
                        label: 'Escuchar la pista en voz alta, botón',
                        button: true,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(160, 42),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                          ),
                          onPressed: _speakCurrentClue,
                          icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF7C3AED), size: 20),
                          label: const Flexible(
                            child: Text(
                              'Escuchar pista',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Zona Interactiva que ocupa el 100% del espacio libre restante
              Expanded(
                child: !_answered
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: q.options.map((option) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Semantics(
                                label: 'Opción: $option. Toca dos veces para elegirla.',
                                button: true,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.surface,
                                    foregroundColor: AppTheme.primary,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: AppTheme.primary.withValues(alpha: 0.35),
                                        width: 2,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                  ),
                                  onPressed: () => _handleOptionSelected(option),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 22,
                                        color: AppTheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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
                                  size: 30,
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
                                          color: _wasCorrect == true ? Colors.green.shade800 : Colors.red.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'El objeto correcto es ${q.correctWordEn} (${q.correctWordEs}).',
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
                          // Botón Siguiente Adivinanza con alto touch target adaptable
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 56),
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
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
                                        : 'SIGUIENTE ADIVINANZA',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
