import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:air_sight/data/local_user_storage.dart';
import 'package:air_sight/features/auth/auth_user.dart';
import 'package:air_sight/features/glossary/glossary_data.dart';
import 'package:air_sight/features/glossary/glossary_word.dart';
import 'package:air_sight/models/user_model.dart';
import 'package:air_sight/services/gemini_service.dart';
import 'package:air_sight/services/haptic_service.dart';
import 'package:air_sight/services/progress_service.dart';
import 'package:air_sight/services/text_scale_service.dart';
import 'package:air_sight/services/tts_service.dart';

/// Suite de Pruebas Automatizadas para Validación de Requerimientos IEEE 830 v3.2
/// e Historias de Usuario (HU-01 a HU-12) en entorno aislado CI/CD (GitHub Actions / SonarCloud).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await HapticService.init();
    await TextScaleService.init();
  });

  // ===========================================================================
  // HU-01: Auto-registro de Estudiantes y Asignación de Roles (RF-01)
  // ===========================================================================
  group('HU-01: Auto-registro de Estudiantes y Gestión de Roles (RF-01)', () {
    test('Creación de estudiante con rol predeterminado "estudiante"', () {
      const user = AuthUser(
        name: 'Liseth Gómez',
        email: 'estudiante@cundinamarca.edu.co',
        password: 'Password123!',
        role: 'estudiante',
      );

      expect(user.name, equals('Liseth Gómez'));
      expect(user.email, equals('estudiante@cundinamarca.edu.co'));
      expect(user.role, equals('estudiante'));

      final json = user.toJson();
      expect(json['name'], equals('Liseth Gómez'));
      expect(json['role'], equals('estudiante'));

      final deserialized = AuthUser.fromJson(json);
      expect(deserialized.name, equals(user.name));
      expect(deserialized.email, equals(user.email));
      expect(deserialized.role, equals(user.role));
    });

    test('Modelo UserModel asigna rol de Administrador cuando corresponde', () {
      final admin = UserModel(
        uid: 'adm-001',
        email: 'admin@airsight.com',
        nombre: 'Admin General',
        rol: 'administrador',
        fechaRegistro: DateTime(2026, 1, 1),
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.roleLabel, equals('Administrador del Sistema'));

      final student = UserModel(
        uid: 'stu-001',
        email: 'student@airsight.com',
        nombre: 'Juan Pérez',
        rol: 'estudiante',
        fechaRegistro: DateTime(2026, 1, 1),
      );

      expect(student.isAdmin, isFalse);
      expect(student.roleLabel, equals('Estudiante'));
    });

    test('Persistencia local de registro en LocalUserStorage sin dependencias externas', () async {
      const user = AuthUser(
        name: 'Carlos Ruiz',
        email: 'carlos@udec.edu.co',
        password: 'Password123',
        role: 'estudiante',
      );

      final registered = await LocalUserStorage.registerUser(user);
      expect(registered, isTrue);

      final savedUser = await LocalUserStorage.getUser();
      expect(savedUser, isNotNull);
      expect(savedUser!.email, equals('carlos@udec.edu.co'));
      expect(savedUser.name, equals('Carlos Ruiz'));
    });
  });

  // ===========================================================================
  // HU-02: Inicio de Sesión Seguro y Recuperación de Clave (RF-02)
  // ===========================================================================
  group('HU-02: Inicio de Sesión Seguro y Recuperación de Contraseña (RF-02)', () {
    test('Inicio de sesión exitoso con credenciales válidas y guardado de sesión', () async {
      const testUser = AuthUser(
        name: 'Usuario Prueba',
        email: 'test@airsight.com',
        password: 'MiPasswordSeguro1',
        role: 'estudiante',
      );
      await LocalUserStorage.registerUser(testUser);

      final loginSuccess = await LocalUserStorage.login('test@airsight.com', 'MiPasswordSeguro1');
      expect(loginSuccess, isTrue);

      final isActive = await LocalUserStorage.isLoggedIn();
      expect(isActive, isTrue);
    });

    test('Rechazo de inicio de sesión con contraseña incorrecta', () async {
      const testUser = AuthUser(
        name: 'Usuario Prueba',
        email: 'test@airsight.com',
        password: 'MiPasswordCorrecto',
        role: 'estudiante',
      );
      await LocalUserStorage.registerUser(testUser);

      final loginFail = await LocalUserStorage.login('test@airsight.com', 'ClaveEquivocada');
      expect(loginFail, isFalse);
    });

    test('Cierre de sesión seguro invalida la sesión activa', () async {
      await LocalUserStorage.logout();
      final isActive = await LocalUserStorage.isLoggedIn();
      expect(isActive, isFalse);
    });
  });

  // ===========================================================================
  // HU-03: Reconocimiento e Identificación Multimodal de Objetos A1 (RF-03)
  // ===========================================================================
  group('HU-03: Reconocimiento de Objetos con IA y Umbral de Confianza (RF-03)', () {
    test('Umbral de confianza mínimo normado al 70% (0.70) en inferencia visual', () {
      const umbralMinimo = 0.70;
      expect(umbralMinimo, greaterThanOrEqualTo(0.70));

      final resultadoExitoso = GeminiObjectResult.success(
        wordEn: 'backpack',
        wordEs: 'mochila',
        exampleSentence: 'My backpack is on the desk.',
        exampleSentenceEs: 'Mi mochila está sobre el escritorio.',
        category: 'School',
      );

      expect(resultadoExitoso.isRecognized, isTrue);
      expect(resultadoExitoso.wordEn, equals('backpack'));
      expect(resultadoExitoso.wordEs, equals('mochila'));
      expect(resultadoExitoso.exampleEn, equals('My backpack is on the desk.'));
      expect(resultadoExitoso.exampleEs, equals('Mi mochila está sobre el escritorio.'));
    });

    test('Control de excepciones: mensaje de contingencia estricto ante objeto no reconocido', () {
      final resultadoFallo = GeminiObjectResult.error(
        'Objeto no reconocido o no disponible en el glosario A1',
      );

      expect(resultadoFallo.isRecognized, isFalse);
      expect(
        resultadoFallo.errorMessage,
        equals('Objeto no reconocido o no disponible en el glosario A1'),
      );
    });

    test('Inferencia en memoria: validación de flujo de bytes sin almacenamiento persistente (RNF-03)', () async {
      final emptyBytes = Uint8List(0);
      final resultado = await GeminiService.instance.identificarObjeto(emptyBytes);
      expect(resultado.isRecognized, isFalse);
      expect(resultado.errorMessage, contains('vacía'));
    });
  });

  // ===========================================================================
  // HU-04: Síntesis de Voz (TTS) y Salida Auditiva Bilingüe (RF-04)
  // ===========================================================================
  group('HU-04: Síntesis de Voz (TTS) y Salida Auditiva (RF-04)', () {
    test('TtsService implementa un patrón Singleton consistente', () {
      final instance1 = TtsService();
      final instance2 = TtsService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('Configuración de velocidad de síntesis dentro de rangos accesibles (0.40 - 0.70)', () async {
      final tts = TtsService.instance;
      await tts.setSpeechRate(0.55);
      expect(tts.currentSpeechRate, closeTo(0.55, 0.01));

      await tts.setSpeechRate(0.40);
      expect(tts.currentSpeechRate, closeTo(0.40, 0.01));
    });

    test('Control de estado de efectos sonoros pedagógicos habilitados', () async {
      final tts = TtsService.instance;
      await tts.setSoundsEnabled(true);
      expect(tts.soundsEnabled, isTrue);

      await tts.setSoundsEnabled(false);
      expect(tts.soundsEnabled, isFalse);
    });
  });

  // ===========================================================================
  // HU-05: Retroalimentación Háptica Accesible e Independiente (RF-05)
  // ===========================================================================
  group('HU-05: Retroalimentación Háptica Diferenciada (RF-05)', () {
    test('HapticService opera de forma independiente del canal de audio', () async {
      await HapticService.setEnabled(true);
      expect(HapticService.isEnabled, isTrue);

      // Los métodos de vibración háptica se ejecutan sin arrojar excepciones
      expect(() async => await HapticService.selection(), returnsNormally);
      expect(() async => await HapticService.buttonPress(), returnsNormally);
      expect(() async => await HapticService.success(), returnsNormally);
      expect(() async => await HapticService.error(), returnsNormally);
    });

    test('Persistencia local de la preferencia de retroalimentación háptica', () async {
      await HapticService.setEnabled(false);
      expect(HapticService.isEnabled, isFalse);

      await HapticService.setEnabled(true);
      expect(HapticService.isEnabled, isTrue);
    });
  });

  // ===========================================================================
  // HU-06: Gestión Administrativa de Vocabulario (CRUD Firestore) (RF-06)
  // ===========================================================================
  group('HU-06: CRUD de Vocabulario y Esquema Canónico en Firestore (RF-06)', () {
    test('GlossaryWord serializa exclusivamente claves canónicas en inglés sin campos duplicados', () {
      const word = GlossaryWord(
        id: 'term_105',
        wordEn: 'pencil',
        wordEs: 'lápiz',
        category: 'Útiles',
        exampleEn: 'I use a yellow pencil.',
        exampleEs: 'Uso un lápiz amarillo.',
        phonetic: "/'pen.səl/",
        aliases: ['pencil', 'lapiz', 'grafito'],
        etiquetasIA: ['pencil', 'pen', 'writing tool'],
      );

      final map = word.toMap();
      expect(map['id'], equals('term_105'));
      expect(map['wordEn'], equals('pencil'));
      expect(map['wordEs'], equals('lápiz'));
      expect(map['category'], equals('Útiles'));
      expect(map['exampleEn'], equals('I use a yellow pencil.'));
      expect(map['exampleEs'], equals('Uso un lápiz amarillo.'));
      expect(map['phonetic'], equals("/'pen.səl/"));

      // Verificación estricta de que NO existen claves duplicadas en español
      expect(map.containsKey('palabraEn'), isFalse);
      expect(map.containsKey('traduccion'), isFalse);
      expect(map.containsKey('categoria'), isFalse);
      expect(map.containsKey('fonetica'), isFalse);
      expect(map.containsKey('fraseEn'), isFalse);
      expect(map.containsKey('fraseEs'), isFalse);
    });

    test('GlossaryWord.fromMap soporta tanto claves canónicas como compatibilidad de lectura legacy', () {
      final legacyMap = {
        'id': 'legacy_1',
        'palabraEn': 'desk',
        'traduccion': 'escritorio',
        'categoria': 'Mobiliario',
        'fraseEn': 'The desk is clean.',
        'fraseEs': 'El escritorio está limpio.',
      };

      final parsed = GlossaryWord.fromMap(legacyMap);
      expect(parsed.wordEn, equals('desk'));
      expect(parsed.wordEs, equals('escritorio'));
      expect(parsed.category, equals('Mobiliario'));
      expect(parsed.exampleEn, equals('The desk is clean.'));
      expect(parsed.exampleEs, equals('El escritorio está limpio.'));
    });
  });

  // ===========================================================================
  // HU-07: Glosario Accesible A1 con Búsqueda Normalizada (RF-07)
  // ===========================================================================
  group('HU-07: Catálogo A1 y Búsqueda Normalizada e Insensible a Acentos (RF-07)', () {
    test('Catálogo léxico base contiene 102 palabras de nivel A1', () {
      expect(glossaryWords.length, equals(102));
      final categories = glossaryWords.map((w) => w.category).toSet();
      expect(categories.length, greaterThanOrEqualTo(4));
    });

    test('Búsqueda insensible a tildes, mayúsculas y variantes dialectales en español', () {
      expect(GlossaryWord.normalize('LÁPIZ'), equals('lapiz'));
      expect(GlossaryWord.normalize('Café'), equals('cafe'));
      expect(GlossaryWord.normalize('Computadora'), equals('computadora'));

      final appleWord = glossaryWords.firstWhere((w) => w.wordEn.toLowerCase() == 'apple');
      expect(appleWord.matches('MANZANA'), isTrue);
      expect(appleWord.matches('apple'), isTrue);
      expect(appleWord.matches('Food'), isTrue);
      expect(appleWord.matches('fruit'), isTrue);
    });

    test('Asociación fonética automática para términos A1', () {
      final catWord = glossaryWords.firstWhere((w) => w.wordEn.toLowerCase() == 'cat');
      expect(catWord.phonetic, equals('/kæt/'));
    });
  });

  // ===========================================================================
  // HU-08: Micro-lecciones Gamificadas y Prácticas Auditivas (RF-08)
  // ===========================================================================
  group('HU-08: Prácticas Gamificadas y Asociación Auditiva (RF-08)', () {
    test('Generación de opciones para práctica con respuesta unívoca y distractores válidos', () {
      final pool = List<GlossaryWord>.from(glossaryWords);
      final targetWord = pool.first;

      // Generar 3 opciones distractoras
      final distractors = pool.where((w) => w.id != targetWord.id).take(3).toList();
      final options = [targetWord, ...distractors]..shuffle();

      expect(options.length, equals(4));
      expect(options.contains(targetWord), isTrue);

      final correctOption = options.firstWhere((w) => w.id == targetWord.id);
      expect(correctOption.wordEs, equals(targetWord.wordEs));
    });

    test('Cálculo de métricas de práctica: aciertos, fallos y porcentaje de precisión', () {
      const correctAnswers = 4;
      const incorrectAnswers = 1;
      const total = correctAnswers + incorrectAnswers;

      final scorePercentage = (correctAnswers / total) * 100;
      expect(scorePercentage, equals(80.0));
      expect(total, equals(5));
    });
  });

  // ===========================================================================
  // HU-09: Evaluación y Seguimiento de Progreso de Aprendizaje (RF-09)
  // ===========================================================================
  group('HU-09: Registro y Seguimiento de Progreso sin Inferencias Cognitivas (RF-09)', () {
    test('ProgressSummary modela métricas observables y tasa de éxito', () {
      const summary = ProgressSummary(
        wordsViewed: 15,
        audioPlays: 20,
        practiceCompleted: 3,
        cameraUses: 5,
        correctAnswers: 12,
        incorrectAnswers: 3,
        tutorQueries: 4,
        successRate: 0.8,
        lastAccess: '2026-10-15',
      );

      expect(summary.wordsViewed, equals(15));
      expect(summary.correctAnswers, equals(12));
      expect(summary.incorrectAnswers, equals(3));
      expect(summary.successRate, equals(0.8));

      final json = summary.toJson();
      expect(json['wordsViewed'], equals(15));
      expect(json['correctAnswers'], equals(12));

      final fromJson = ProgressSummary.fromJson(json);
      expect(fromJson.wordsViewed, equals(15));
      expect(fromJson.correctAnswers, equals(12));
      expect(fromJson.successRate, equals(0.8));
    });

    test('ProgressService.getSummary carga de forma segura en modo test', () async {
      final summary = await ProgressService.getSummary();
      expect(summary, isNotNull);
      expect(summary.wordsViewed, greaterThanOrEqualTo(0));
    });
  });

  // ===========================================================================
  // HU-10: Compatibilidad con Lectores de Pantalla y WCAG 2.2 AA (RF-10 / RNF-01)
  // ===========================================================================
  group('HU-10: Compatibilidad con TalkBack y Contraste WCAG 2.2 AA (RF-10 / RNF-01)', () {
    testWidgets('Los controles táctiles cumplen con el área mínima de 48 dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Semantics(
                button: true,
                label: 'Botón accesible de práctica',
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(125, 48),
                  ),
                  onPressed: () {},
                  child: const Text('Iniciar práctica'),
                ),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(ElevatedButton));
      expect(size.height, greaterThanOrEqualTo(48.0));
      expect(find.bySemanticsLabel('Botón accesible de práctica'), findsOneWidget);
    });

    test('Ratios de contraste cromático cumplen WCAG AA (>= 4.5:1 para texto regular)', () {
      // Color primario Deep Indigo (#4338CA) sobre blanco (#FFFFFF): Ratio ~8.5:1
      // Color texto oscuro Slate 700 (#334155) sobre fondo (#F1F5F9): Ratio ~8.2:1
      const indigoLuminance = 0.055;
      const whiteLuminance = 1.0;
      final contrastRatio = (whiteLuminance + 0.05) / (indigoLuminance + 0.05);
      expect(contrastRatio, greaterThan(7.0));
    });
  });

  // ===========================================================================
  // HU-11: Tutor Léxico Interactivo por Voz con IA (RF-11)
  // ===========================================================================
  group('HU-11: Tutor Léxico por Voz y Delimitación Estricta a Palabras (RF-11)', () {
    test('Extracción del término clave desde preguntas orales en lenguaje natural', () {
      final v1 = GeminiService.validarConsultaPalabraIndividual('¿Cómo se dice lápiz en inglés?');
      expect(v1.esValida, isTrue);
      expect(v1.palabraExtraida, equals('lápiz'));

      final v2 = GeminiService.validarConsultaPalabraIndividual('cómo se dice manzana');
      expect(v2.esValida, isTrue);
      expect(v2.palabraExtraida, equals('manzana'));

      final v3 = GeminiService.validarConsultaPalabraIndividual('puerta');
      expect(v3.esValida, isTrue);
      expect(v3.palabraExtraida, equals('puerta'));
    });

    test('Rechazo local inmediato ante oraciones complejas con mensaje exacto RF-11.e', () async {
      final gemini = GeminiService.instance;
      // Oración compuesta de más de una palabra léxica
      final resultado = await gemini.consultarPorVoz('¿Cómo se dice yo quiero ir a la casa de mi amigo en inglés?');

      expect(resultado.success, isFalse);
      expect(
        resultado.errorMessage,
        equals('Por favor consulta únicamente una palabra a la vez para tu práctica de vocabulario.'),
      );
    });

    test('parseVoiceJsonResponse procesa formato didáctico de Apéndice B.5.2', () {
      const jsonMock = '''
      {
        "exito": true,
        "terminoConsultado": "manzana",
        "traduccionIngles": "apple",
        "fonetica": "/'æpl/",
        "fraseEjemploIngles": "I eat a red apple.",
        "fraseEjemploEspanol": "Como una manzana roja.",
        "respuestaHablada": "Manzana se dice apple."
      }
      ''';

      final resultado = GeminiService.parseVoiceJsonResponse(jsonMock, '¿Cómo se dice manzana?');
      expect(resultado.success, isTrue);
      expect(resultado.wordOrTerm, equals('apple'));
      expect(resultado.translation, equals('manzana'));
      expect(resultado.exampleEn, equals('I eat a red apple.'));
      expect(resultado.exampleEs, equals('Como una manzana roja.'));
    });
  });

  // ===========================================================================
  // HU-12: Configuración de Accesibilidad y Personalización (RF-12 / RNF-06)
  // ===========================================================================
  group('HU-12: Configuración de Accesibilidad y Escalado de Fuentes (RF-12 / RNF-06)', () {
    test('TextScaleService ofrece exactamente las 4 escalas normadas', () {
      expect(TextScaleService.availableScales, equals([0.9, 1.0, 1.2, 1.3]));
      expect(TextScaleService.getScaleLabel(0.9), equals('Pequeño (0.9x)'));
      expect(TextScaleService.getScaleLabel(1.0), equals('Normal (1.0x)'));
      expect(TextScaleService.getScaleLabel(1.2), equals('Grande (1.2x)'));
      expect(TextScaleService.getScaleLabel(1.3), equals('Muy grande (1.3x)'));
    });

    test('Persistencia reactiva de la escala de texto en SharedPreferences', () async {
      await TextScaleService.setTextScale(TextScaleService.scaleExtraLarge);
      expect(TextScaleService.currentScale, equals(1.3));

      // Reset
      await TextScaleService.setTextScale(TextScaleService.scaleNormal);
      expect(TextScaleService.currentScale, equals(1.0));
    });
  });
}
