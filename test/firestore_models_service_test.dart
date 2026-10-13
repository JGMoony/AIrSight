import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:air_sight/features/glossary/glossary_word.dart';
import 'package:air_sight/models/device_model.dart';
import 'package:air_sight/models/measurement_model.dart';
import 'package:air_sight/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas de UserModel', () {
    test('Serialización toMap estricta a 5 campos canónicos (uid, email, nombre, rol, fechaRegistro)', () {
      final now = DateTime(2026, 10, 1, 15, 30);
      final user = UserModel(
        uid: 'usr_123',
        nombre: 'Carlos Perez',
        email: 'Carlos@AirSight.com',
        rol: 'estudiante',
        fechaRegistro: now,
      );

      final map = user.toMap();
      // Campos canónicos obligatorios
      expect(map['uid'], equals('usr_123'));
      expect(map['nombre'], equals('Carlos Perez'));
      expect(map['email'], equals('carlos@airsight.com'));
      expect(map['rol'], equals('estudiante'));
      expect(map['fechaRegistro'], isA<Timestamp>());

      // Sin campos redundantes o legados
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('name'), isFalse);
      expect(map.containsKey('role'), isFalse);
      expect(map.containsKey('createdAt'), isFalse);

      final userFromMap = UserModel.fromMap(map, id: 'usr_123');
      expect(userFromMap.uid, equals('usr_123'));
      expect(userFromMap.id, equals('usr_123'));
      expect(userFromMap.nombre, equals('Carlos Perez'));
      expect(userFromMap.email, equals('carlos@airsight.com'));
      expect(userFromMap.rol, equals('estudiante'));
      expect(userFromMap.fechaRegistro, equals(now));
    });

    test('copyWith y equality funcionan como se espera', () {
      final now = DateTime.now();
      final user1 = UserModel(
        id: 'u1',
        nombre: 'Ana',
        email: 'ana@mail.com',
        rol: 'administrador',
        fechaRegistro: now,
      );

      final user2 = user1.copyWith(nombre: 'Ana Maria');
      expect(user2.id, equals('u1'));
      expect(user2.nombre, equals('Ana Maria'));
      expect(user2.email, equals('ana@mail.com'));
      expect(user1 == user2, isFalse);

      final user3 = user2.copyWith(nombre: 'Ana');
      expect(user1 == user3, isTrue);
      expect(user1.hashCode, equals(user3.hashCode));
    });
  });

  group('Pruebas de DeviceModel', () {
    test('Serialización y deserialización toMap / fromMap correcta', () {
      final now = DateTime(2026, 10, 1, 18, 0);
      final device = DeviceModel(
        id: 'dev_456',
        codigoSerie: 'AIR-SIGHT-001',
        nombre: 'Sensor Aula 101',
        estado: 'activo',
        userIdAsociado: 'usr_123',
        ultimaConexion: now,
      );

      final map = device.toMap();
      expect(map['id'], equals('dev_456'));
      expect(map['codigoSerie'], equals('AIR-SIGHT-001'));
      expect(map['nombre'], equals('Sensor Aula 101'));
      expect(map['estado'], equals('activo'));
      expect(map['userIdAsociado'], equals('usr_123'));
      expect(map['ultimaConexion'], isA<Timestamp>());

      final deviceFromMap = DeviceModel.fromMap(map, id: 'dev_456');
      expect(deviceFromMap.id, equals('dev_456'));
      expect(deviceFromMap.codigoSerie, equals('AIR-SIGHT-001'));
      expect(deviceFromMap.estado, equals('activo'));
      expect(deviceFromMap.userIdAsociado, equals('usr_123'));
      expect(deviceFromMap.ultimaConexion, equals(now));
    });

    test('copyWith y equality de DeviceModel', () {
      final now = DateTime.now();
      final dev1 = DeviceModel(
        id: 'd1',
        codigoSerie: 'SN01',
        nombre: 'D1',
        estado: 'inactivo',
        userIdAsociado: 'u1',
        ultimaConexion: now,
      );

      final dev2 = dev1.copyWith(estado: 'activo');
      expect(dev2.estado, equals('activo'));
      expect(dev1 == dev2, isFalse);
    });
  });

  group('Pruebas de MeasurementModel', () {
    test('Serialización y parsing numérico robusto en toMap / fromMap', () {
      final now = DateTime(2026, 10, 1, 20, 15);
      final measurement = MeasurementModel(
        id: 'm_789',
        deviceId: 'dev_456',
        variable: 'temperatura',
        valor: 24.5,
        unidad: '°C',
        timestamp: now,
      );

      final map = measurement.toMap();
      expect(map['id'], equals('m_789'));
      expect(map['deviceId'], equals('dev_456'));
      expect(map['variable'], equals('temperatura'));
      expect(map['valor'], equals(24.5));
      expect(map['unidad'], equals('°C'));
      expect(map['timestamp'], isA<Timestamp>());

      final measurementFromMap =
          MeasurementModel.fromMap(map, id: 'm_789');
      expect(measurementFromMap.id, equals('m_789'));
      expect(measurementFromMap.deviceId, equals('dev_456'));
      expect(measurementFromMap.variable, equals('temperatura'));
      expect(measurementFromMap.valor, equals(24.5));
      expect(measurementFromMap.unidad, equals('°C'));
      expect(measurementFromMap.timestamp, equals(now));
    });

    test('Parsing de valor numérico como int o string', () {
      final now = DateTime.now();
      final mapWithInt = {
        'deviceId': 'd1',
        'variable': 'co2',
        'valor': 420, // int
        'unidad': 'ppm',
        'timestamp': now,
      };

      final m1 = MeasurementModel.fromMap(mapWithInt, id: 'm1');
      expect(m1.valor, equals(420.0));

      final mapWithString = {
        'deviceId': 'd1',
        'variable': 'humedad',
        'valor': '65.8', // String
        'unidad': '%',
        'timestamp': now,
      };

      final m2 = MeasurementModel.fromMap(mapWithString, id: 'm2');
      expect(m2.valor, equals(65.8));
    });
  });

  group('Pruebas de Glosario A1 y Compatibilidad de Colección users', () {
    test('UserModel deserializa campos legados en inglés (name, role, createdAt) y los migra a formato canónico', () {
      final now = DateTime(2026, 10, 1, 10, 0);
      final rawFirestoreUsersMap = {
        'uid': 'usr_google_789',
        'name': 'Sofia Gomez',
        'email': 'sofia@gmail.com',
        'role': 'student',
        'createdAt': Timestamp.fromDate(now),
      };

      final user = UserModel.fromMap(rawFirestoreUsersMap);
      expect(user.uid, equals('usr_google_789'));
      expect(user.id, equals('usr_google_789'));
      expect(user.nombre, equals('Sofia Gomez'));
      expect(user.email, equals('sofia@gmail.com'));
      expect(user.rol, equals('estudiante'));
      expect(user.fechaRegistro, equals(now));

      final serialized = user.toMap();
      expect(serialized['uid'], equals('usr_google_789'));
      expect(serialized['nombre'], equals('Sofia Gomez'));
      expect(serialized['email'], equals('sofia@gmail.com'));
      expect(serialized['rol'], equals('estudiante'));
      expect(serialized.containsKey('name'), isFalse);
      expect(serialized.containsKey('role'), isFalse);
      expect(serialized.containsKey('createdAt'), isFalse);
      expect(serialized.containsKey('id'), isFalse);
    });

    test('GlossaryWord serializa y deserializa fonética y etiquetas IA para glosario_a1', () {
      const word = GlossaryWord(
        id: '1',
        wordEn: 'bird',
        wordEs: 'pájaro',
        category: 'Animals',
        exampleEn: 'The bird is small.',
        exampleEs: 'El pájaro es pequeño.',
        phonetic: '/bɜːrd/',
        aliases: ['bird', 'animal'],
        etiquetasIA: ['bird', 'animal'],
      );

      final map = word.toFirestore();
      expect(map['id'], equals('1'));
      expect(map['wordEn'], equals('bird'));
      expect(map['palabraEn'], equals('bird'));
      expect(map['wordEs'], equals('pájaro'));
      expect(map['traduccion'], equals('pájaro'));
      expect(map['phonetic'], equals('/bɜːrd/'));
      expect(map['fonetica'], equals('/bɜːrd/'));
      expect(map['etiquetasIA'], contains('bird'));

      final fromMap = GlossaryWord.fromMap(map);
      expect(fromMap.id, equals('1'));
      expect(fromMap.wordEn, equals('bird'));
      expect(fromMap.wordEs, equals('pájaro'));
      expect(fromMap.phonetic, equals('/bɜːrd/'));
      expect(fromMap.matchesAiLabel('bird'), isTrue);
    });

    test('UserModel evalúa correctamente isAdmin, isStudent y roleLabel para estudiante y administrador', () {
      final now = DateTime.now();

      final studentUser = UserModel(
        id: 'u_student',
        nombre: 'Pedro',
        email: 'pedro@mail.com',
        rol: 'estudiante',
        fechaRegistro: now,
      );
      expect(studentUser.isAdmin, isFalse);
      expect(studentUser.isStudent, isTrue);
      expect(studentUser.roleLabel, equals('Estudiante'));

      final studentLegacy = UserModel(
        id: 'u_student_legacy',
        nombre: 'Pedro 2',
        email: 'pedro2@mail.com',
        rol: 'student',
        fechaRegistro: now,
      );
      expect(studentLegacy.isAdmin, isFalse);
      expect(studentLegacy.isStudent, isTrue);

      final adminUser = UserModel(
        id: 'u_admin',
        nombre: 'Admin UDEC',
        email: 'admin@airsight.com',
        rol: 'administrador',
        fechaRegistro: now,
      );
      expect(adminUser.isAdmin, isTrue);
      expect(adminUser.isStudent, isFalse);
      expect(adminUser.roleLabel, equals('Administrador del Sistema'));

      final adminLegacy = UserModel(
        id: 'u_admin_legacy',
        nombre: 'Admin 2',
        email: 'admin2@mail.com',
        rol: 'admin',
        fechaRegistro: now,
      );
      expect(adminLegacy.isAdmin, isTrue);
      expect(adminLegacy.isStudent, isFalse);
    });
  });
}
