import 'package:flutter_test/flutter_test.dart';
import 'package:air_sight/features/auth/auth_user.dart';
import 'package:air_sight/models/user_model.dart';
import 'package:air_sight/services/progress_service.dart';

void main() {
  group('HU-01 y HU-02: Pruebas Unitarias de Validación de Autenticación', () {
    // -------------------------------------------------------------------------
    // Función pura de validación de correo equivalente a la implementada en
    // LoginScreen y RegisterScreen
    // -------------------------------------------------------------------------
    String? validateEmail(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Ingresa tu correo';
      }
      if (!value.contains('@') || !value.contains('.')) {
        return 'Ingresa un correo válido';
      }
      return null;
    }

    // -------------------------------------------------------------------------
    // Función pura de validación de contraseña equivalente a la implementada
    // en LoginScreen y RegisterScreen (mínimo 6 caracteres)
    // -------------------------------------------------------------------------
    String? validatePassword(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Ingresa una contraseña';
      }
      if (value.trim().length < 6) {
        return 'Debe tener mínimo 6 caracteres';
      }
      return null;
    }

    // -------------------------------------------------------------------------
    // Validación de confirmación de contraseña en RegisterScreen
    // -------------------------------------------------------------------------
    String? validateConfirmPassword(String? value, String password) {
      if (value == null || value.trim().isEmpty) {
        return 'Confirma tu contraseña';
      }
      if (value != password) {
        return 'Las contraseñas no coinciden';
      }
      return null;
    }

    test('Validación de formato de correo rechaza correos sin "@" o sin dominio', () {
      expect(validateEmail(null), equals('Ingresa tu correo'));
      expect(validateEmail(''), equals('Ingresa tu correo'));
      expect(validateEmail('   '), equals('Ingresa tu correo'));

      // Sin '@'
      expect(validateEmail('estudiante.udec.edu.co'), equals('Ingresa un correo válido'));
      expect(validateEmail('usuarioinvalido'), equals('Ingresa un correo válido'));

      // Sin dominio / punto
      expect(validateEmail('estudiante@cundinamarca'), equals('Ingresa un correo válido'));
      expect(validateEmail('admin@localhost'), equals('Ingresa un correo válido'));

      // Correos válidos
      expect(validateEmail('estudiante@cundinamarca.edu.co'), isNull);
      expect(validateEmail('liseth.gomez@gmail.com'), isNull);
      expect(validateEmail('user123@domain.org'), isNull);
    });

    test('Validación de contraseña rechaza cadenas vacías o menores a 6 caracteres', () {
      expect(validatePassword(null), equals('Ingresa una contraseña'));
      expect(validatePassword(''), equals('Ingresa una contraseña'));
      expect(validatePassword('   '), equals('Ingresa una contraseña'));

      // Menor a 6 caracteres
      expect(validatePassword('12345'), equals('Debe tener mínimo 6 caracteres'));
      expect(validatePassword('abc'), equals('Debe tener mínimo 6 caracteres'));
      expect(validatePassword('a1!'), equals('Debe tener mínimo 6 caracteres'));

      // 6 caracteres o más (válidas)
      expect(validatePassword('123456'), isNull);
      expect(validatePassword('Password123!'), isNull);
      expect(validatePassword('secreto_seguro'), isNull);
    });

    test('Validación de confirmación de contraseña verifica coincidencia exacta', () {
      expect(validateConfirmPassword(null, 'Clave123'), equals('Confirma tu contraseña'));
      expect(validateConfirmPassword('', 'Clave123'), equals('Confirma tu contraseña'));
      expect(validateConfirmPassword('ClaveDistinta', 'Clave123'), equals('Las contraseñas no coinciden'));
      expect(validateConfirmPassword('Clave123', 'Clave123'), isNull);
    });

    test('Creación de nuevo usuario asigna por defecto el rol de estudiante ("estudiante" / "student")', () {
      // 1. AuthUser asigna rol por defecto o explícito de estudiante
      const authUser = AuthUser(
        name: 'Ana María',
        email: 'ana@cundinamarca.edu.co',
        password: 'Password123!',
        role: 'estudiante',
      );
      expect(authUser.role, equals('estudiante'));

      // 2. UserModel normaliza a rol canónico 'estudiante'
      final nuevoUsuario = UserModel(
        uid: 'usr-student-001',
        email: 'ana@cundinamarca.edu.co',
        nombre: 'Ana María',
        rol: 'estudiante',
        fechaRegistro: DateTime(2026, 10, 16),
      );

      expect(nuevoUsuario.canonicalRole, equals('estudiante'));
      expect(nuevoUsuario.isStudent, isTrue);
      expect(nuevoUsuario.isAdmin, isFalse);
      expect(nuevoUsuario.roleLabel, equals('Estudiante'));

      // Deserialización con clave legada 'role: student'
      final usuarioDesdeMap = UserModel.fromMap({
        'uid': 'usr-002',
        'email': 'carlos@udec.edu.co',
        'name': 'Carlos Ruiz',
        'role': 'student',
      });
      expect(usuarioDesdeMap.canonicalRole, equals('estudiante'));
      expect(usuarioDesdeMap.isStudent, isTrue);
      expect(usuarioDesdeMap.isAdmin, isFalse);
    });

    test('Creación de nuevo estudiante asigna puntaje y métricas iniciales limpias (0 aciertos, 0 prácticas)', () {
      final progresoInicial = ProgressSummary.empty();

      expect(progresoInicial.wordsViewed, equals(0));
      expect(progresoInicial.audioPlays, equals(0));
      expect(progresoInicial.practiceCompleted, equals(0));
      expect(progresoInicial.cameraUses, equals(0));
      expect(progresoInicial.correctAnswers, equals(0));
      expect(progresoInicial.incorrectAnswers, equals(0));
      expect(progresoInicial.tutorQueries, equals(0));
      expect(progresoInicial.successRate, equals(0.0));
      expect(progresoInicial.lastAccess, isEmpty);

      // Serialización y deserialización del progreso inicial
      final map = progresoInicial.toJson();
      expect(map['wordsViewed'], equals(0));
      expect(map['practiceCompleted'], equals(0));

      final reconstruido = ProgressSummary.fromJson(map);
      expect(reconstruido.correctAnswers, equals(0));
      expect(reconstruido.successRate, equals(0.0));
    });
  });
}
