import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_sight/features/practice/riddle_practice_screen.dart';
import 'package:air_sight/features/practice/true_false_practice_screen.dart';
import 'package:air_sight/models/user_model.dart';
import 'package:air_sight/services/metrics_export_service.dart';

void main() {
  group('Módulo de Práctica: RiddleQuestion & Sincronización de Pistas', () {
    test('RiddleQuestion contiene siempre la palabra correcta en sus opciones', () {
      final question = RiddleQuestion(
        id: 'r_bus',
        clueEs: 'Vehículo de transporte público grande que lleva muchos pasajeros.',
        correctWordEn: 'Bus',
        correctWordEs: 'autobús',
        distractorsEn: ['Car', 'Bicycle'],
      );

      expect(question.options.length, 3);
      expect(question.options.contains('Bus'), isTrue);
      expect(question.options.contains('Car'), isTrue);
      expect(question.options.contains('Bicycle'), isTrue);
      expect(question.correctWordEn, 'Bus');
      expect(question.correctWordEs, 'autobús');
      expect(question.clueEs, contains('transporte'));
    });

    test('RiddleQuestion no depende del primer índice del glosario estático', () {
      final question1 = RiddleQuestion(
        id: 'r_shoes',
        clueEs: 'Prendas de vestir que te pones en los pies.',
        correctWordEn: 'Shoes',
        correctWordEs: 'zapatos',
        distractorsEn: ['Hat', 'Socks'],
      );

      final question2 = RiddleQuestion(
        id: 'r_dog',
        clueEs: 'Animal doméstico leal que ladra.',
        correctWordEn: 'Dog',
        correctWordEs: 'perro',
        distractorsEn: ['Cat', 'Cow'],
      );

      expect(question1.options.contains('Shoes'), isTrue);
      expect(question1.options.contains('Bird'), isFalse);

      expect(question2.options.contains('Dog'), isTrue);
      expect(question2.options.contains('Bird'), isFalse);
    });
  });

  group('Módulo Admin: MetricsExportService (Exportación CSV)', () {
    final mockUser = UserModel(
      uid: 'user_123',
      email: 'juan.perez@universidad.edu.co',
      nombre: 'Juan Pérez',
      rol: 'estudiante',
      fechaRegistro: DateTime(2026, 10, 1),
    );

    final mockSummaries = [
      {
        'userId': 'user_123',
        'wordsViewed': 45,
        'audioPlays': 30,
        'practiceCompleted': 12,
        'cameraUses': 8,
        'correctAnswers': 40,
        'incorrectAnswers': 10,
        'lastAccess': '19/10/2026 10:30',
      },
      {
        'userId': 'user_456',
        'studentName': 'María Gómez',
        'studentEmail': 'maria@universidad.edu.co',
        'wordsViewed': 20,
        'audioPlays': 15,
        'practiceCompleted': 5,
        'cameraUses': 4,
        'correctAnswers': 18,
        'incorrectAnswers': 2,
        'lastAccess': '19/10/2026 09:15',
      },
    ];

    test('generateGlobalCsv incluye cabeceras, resolución de usuarios y totales acumulados', () {
      final usersMap = {'user_123': mockUser};

      final csv = MetricsExportService.generateGlobalCsv(mockSummaries, usersMap);

      expect(csv, contains('"Estudiante","Email","UID"'));
      expect(csv, contains('Juan Pérez'));
      expect(csv, contains('juan.perez@universidad.edu.co'));
      expect(csv, contains('user_123'));
      expect(csv, contains('María Gómez'));
      expect(csv, contains('TOTALES PILOTO'));
      // Total de palabras: 45 + 20 = 65
      expect(csv, contains(',65,'));
      // Total de aciertos: 40 + 18 = 58
      expect(csv, contains(',58,'));
    });

    test('generateStudentCsv genera formato métrica-valor para estudiante individual', () {
      final metrics = mockSummaries.first;

      final csv = MetricsExportService.generateStudentCsv(
        studentName: 'Juan Pérez',
        studentEmail: 'juan.perez@universidad.edu.co',
        userId: 'user_123',
        metrics: metrics,
      );

      expect(csv, contains('"Metrica","Valor"'));
      expect(csv, contains('"Estudiante","Juan Pérez"'));
      expect(csv, contains('"Email","juan.perez@universidad.edu.co"'));
      expect(csv, contains('"UID","user_123"'));
      expect(csv, contains('"Palabras Exploradas","45"'));
      expect(csv, contains('"Reproducciones de Audio","30"'));
      expect(csv, contains('"Practicas Completadas","12"'));
      expect(csv, contains('"Usos de Camara","8"'));
      expect(csv, contains('"Respuestas Correctas","40"'));
      expect(csv, contains('"Respuestas Incorrectas","10"'));
      expect(csv, contains('"Precision","80.0%"'));
      expect(csv, contains('"Ultimo Acceso","19/10/2026 10:30"'));
    });
  });

  group('Control de Salida Anticipada con PopScope', () {
    testWidgets('TrueFalsePracticeScreen envuelve la pantalla con PopScope', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TrueFalsePracticeScreen(questionLimit: 5),
        ),
      );
      await tester.pump();

      expect(find.byWidgetPredicate((w) => w is PopScope), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('RiddlePracticeScreen envuelve la pantalla con PopScope', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RiddlePracticeScreen(questionLimit: 5),
        ),
      );
      await tester.pump();

      expect(find.byWidgetPredicate((w) => w is PopScope), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });
  });
}
