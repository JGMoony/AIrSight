import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../features/glossary/glossary_data.dart';
import '../features/glossary/glossary_word.dart';
import '../models/device_model.dart';
import '../models/measurement_model.dart';
import '../models/user_model.dart';

/// Servicio de acceso y manipulación de datos en Cloud Firestore.
/// Gestiona las colecciones:
/// - 'users': Perfiles y roles de los usuarios del sistema.
/// - 'dispositivos': Dispositivos IoT asociados a cada usuario.
/// - 'mediciones': Subcolección de telemetría ('dispositivos/{deviceId}/mediciones').
/// - 'glosario_a1': Catálogo accesible A1 con soporte para reconocimiento por IA.
/// - 'progreso_metricas': Registro de métricas cuantitativas del piloto de grado.
class FirestoreService {
  final FirebaseFirestore _firestore;

  static final FirestoreService _instance = FirestoreService._internal();

  /// Constructor de fábrica que retorna la instancia Singleton.
  factory FirestoreService({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return FirestoreService._internal(firestore: firestore);
    }
    return _instance;
  }

  /// Instancia estática de acceso rápido.
  static FirestoreService get instance => _instance;

  FirestoreService._internal({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ===========================================================================
  // MÉTODOS DE USUARIO ('users')
  // ===========================================================================

  /// Guarda o actualiza el perfil del usuario en la colección 'users'.
  /// Guarda estrictamente los 5 campos canónicos (uid, email, nombre, rol, fechaRegistro)
  /// y elimina campos inconsistentes o legados (role, name, id, createdAt).
  Future<void> saveUser(UserModel user) async {
    try {
      if (user.uid.isEmpty) {
        throw ArgumentError('El UID del usuario no puede estar vacío.');
      }
      debugPrint('[FirestoreService] Guardando usuario en Firestore: ${user.uid}');
      await _firestore.collection('users').doc(user.uid).set({
        ...user.toMap(),
        'role': FieldValue.delete(),
        'name': FieldValue.delete(),
        'id': FieldValue.delete(),
        'createdAt': FieldValue.delete(),
      }, SetOptions(merge: true));
      debugPrint('[FirestoreService] Usuario guardado exitosamente: ${user.uid}');
    } catch (e, stackTrace) {
      debugPrint('[FirestoreService] Error al guardar usuario: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Consulta puntual del perfil de un usuario por su ID en 'users'.
  Future<UserModel?> getUser(String userId) async {
    try {
      if (userId.isEmpty) return null;
      debugPrint('[FirestoreService] Consultando usuario: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserModel.fromDocumentSnapshot(doc);
    } catch (e, stackTrace) {
      debugPrint('[FirestoreService] Error al obtener usuario $userId: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Consulta un usuario en 'users' buscando por su correo electrónico exacto.
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      if (cleanEmail.isEmpty) return null;
      debugPrint('[FirestoreService] Buscando usuario por email: $cleanEmail');
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return UserModel.fromDocumentSnapshot(query.docs.first);
    } catch (e, stackTrace) {
      debugPrint('[FirestoreService] Error al buscar usuario por email: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Stream reactivo de los datos de un usuario en 'users'.
  Stream<UserModel?> streamUser(String userId) {
    if (userId.isEmpty) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null
            ? UserModel.fromDocumentSnapshot(doc)
            : null);
  }

  /// Stream reactivo de todos los usuarios registrados en 'users' para el panel de administración.
  Stream<List<UserModel>> streamAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromDocumentSnapshot(doc))
            .toList());
  }

  /// Consulta todos los usuarios registrados en 'users'.
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('[FirestoreService] Error al obtener todos los usuarios: $e');
      debugPrint('StackTrace: $stackTrace');
      return [];
    }
  }

  /// Asigna el rol canónico ('administrador' o 'estudiante') a un usuario por su UID.
  /// Limpia automáticamente campos legados como 'role'.
  Future<void> setUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      if (userId.isEmpty) {
        throw ArgumentError('El ID del usuario no puede estar vacío.');
      }
      final clean = role.trim().toLowerCase();
      final canonicalRole =
          (clean == 'admin' || clean == 'administrador')
              ? 'administrador'
              : 'estudiante';

      debugPrint(
        '[FirestoreService] Actualizando rol de $userId a "$canonicalRole"',
      );
      await _firestore.collection('users').doc(userId).set({
        'rol': canonicalRole,
        'role': FieldValue.delete(),
        'name': FieldValue.delete(),
        'id': FieldValue.delete(),
        'createdAt': FieldValue.delete(),
      }, SetOptions(merge: true));
      debugPrint('[FirestoreService] Rol actualizado con éxito para $userId.');
    } catch (e, stackTrace) {
      debugPrint('[FirestoreService] Error al actualizar rol de usuario: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  // ===========================================================================
  // MÉTODOS DE DISPOSITIVOS ('dispositivos')
  // ===========================================================================

  /// Registra un nuevo dispositivo IoT o actualiza uno existente.
  /// Si el ID está vacío, genera automáticamente un ID único en Firestore.
  Future<String> registerDevice(DeviceModel device) async {
    try {
      debugPrint('[FirestoreService] Registrando dispositivo: ${device.codigoSerie}');
      final collection = _firestore.collection('dispositivos');

      if (device.id.isEmpty) {
        final docRef = collection.doc();
        final deviceWithId = device.copyWith(id: docRef.id);
        await docRef.set(deviceWithId.toMap());
        debugPrint('[FirestoreService] Dispositivo registrado con ID: ${docRef.id}');
        return docRef.id;
      } else {
        await collection
            .doc(device.id)
            .set(device.toMap(), SetOptions(merge: true));
        debugPrint('[FirestoreService] Dispositivo actualizado con ID: ${device.id}');
        return device.id;
      }
    } catch (e, stackTrace) {
      debugPrint('[FirestoreService] Error al registrar dispositivo: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Consulta todos los dispositivos IoT asociados a un usuario específico.
  Future<List<DeviceModel>> getDevicesByUserId(String userId) async {
    try {
      debugPrint('[FirestoreService] Consultando dispositivos del usuario: $userId');
      final querySnapshot = await _firestore
          .collection('dispositivos')
          .where('userIdAsociado', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => DeviceModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('[FirestoreService] Error al consultar dispositivos por userId: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Stream reactivo de los dispositivos IoT asociados a un usuario.
  Stream<List<DeviceModel>> streamDevicesByUserId(String userId) {
    return _firestore
        .collection('dispositivos')
        .where('userIdAsociado', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeviceModel.fromDocumentSnapshot(doc))
            .toList());
  }

  /// Consulta un dispositivo específico por su ID.
  Future<DeviceModel?> getDeviceById(String deviceId) async {
    try {
      if (deviceId.isEmpty) return null;
      final doc = await _firestore.collection('dispositivos').doc(deviceId).get();
      if (!doc.exists || doc.data() == null) return null;
      return DeviceModel.fromDocumentSnapshot(doc);
    } catch (e, stackTrace) {
      debugPrint('[FirestoreService] Error al obtener dispositivo $deviceId: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  // ===========================================================================
  // MÉTODOS DE TELEMETRÍA / MEDICIONES
  // ===========================================================================

  /// Agrega una nueva lectura de sensor / telemetría a Firestore.
  /// Guarda la medición en la subcolección 'dispositivos/{deviceId}/mediciones'
  /// y actualiza el campo 'ultimaConexion' del dispositivo IoT padre.
  Future<String> saveMeasurement(MeasurementModel measurement) async {
    try {
      if (measurement.deviceId.isEmpty) {
        throw ArgumentError('El deviceId de la medición no puede estar vacío.');
      }

      debugPrint(
        '[FirestoreService] Guardando medición [${measurement.variable}: ${measurement.valor} ${measurement.unidad}] para dispositivo: ${measurement.deviceId}',
      );

      final measurementsSubcollection = _firestore
          .collection('dispositivos')
          .doc(measurement.deviceId)
          .collection('mediciones');

      final DocumentReference docRef = measurement.id.isEmpty
          ? measurementsSubcollection.doc()
          : measurementsSubcollection.doc(measurement.id);

      final measurementData = measurement.copyWith(id: docRef.id).toMap();

      // Guardar en la subcolección del dispositivo
      await docRef.set(measurementData, SetOptions(merge: true));

      // Actualizar automáticamente la última conexión del dispositivo padre
      try {
        await _firestore
            .collection('dispositivos')
            .doc(measurement.deviceId)
            .update({
          'ultimaConexion': Timestamp.fromDate(measurement.timestamp),
          'estado': 'activo',
        });
      } catch (e) {
        // Si el dispositivo padre aún no existe o falla la actualización, no bloquea la medición
        debugPrint(
          '[FirestoreService] Aviso: No se pudo actualizar estado/conexión del dispositivo padre: $e',
        );
      }

      debugPrint('[FirestoreService] Medición guardada con ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      debugPrint('[FirestoreService] Error al guardar medición: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Retorna un Stream con las últimas mediciones de un dispositivo ordenadas
  /// descendentemente por timestamp para pintar gráficos y tarjetas en tiempo real.
  Stream<List<MeasurementModel>> streamLatestMeasurements(
    String deviceId, {
    int limit = 50,
  }) {
    if (deviceId.isEmpty) {
      return Stream.value(<MeasurementModel>[]);
    }

    return _firestore
        .collection('dispositivos')
        .doc(deviceId)
        .collection('mediciones')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MeasurementModel.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  /// Consulta puntual de las últimas mediciones para un dispositivo.
  Future<List<MeasurementModel>> getLatestMeasurements(
    String deviceId, {
    int limit = 50,
  }) async {
    try {
      if (deviceId.isEmpty) return [];

      final querySnapshot = await _firestore
          .collection('dispositivos')
          .doc(deviceId)
          .collection('mediciones')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => MeasurementModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e, stackTrace) {
      debugPrint(
        '[FirestoreService] Error al consultar últimas mediciones para $deviceId: $e',
      );
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  // ===========================================================================
  // MÉTODOS DE GLOSARIO A1 ('glosario_a1')
  // ===========================================================================

  /// Stream en tiempo real de las palabras del catálogo A1 desde 'glosario_a1'.
  /// Si se especifica una categoría, filtra los resultados.
  Stream<List<GlossaryWord>> streamGlossaryWords({String? category}) {
    Query<Map<String, dynamic>> query = _firestore.collection('glosario_a1');
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Fallback al catálogo local en memoria si la colección aún no está poblada
        final localList = (category != null && category.isNotEmpty)
            ? glossaryWords.where((w) => w.category == category).toList()
            : glossaryWords;
        return localList;
      }
      return snapshot.docs
          .map((doc) => GlossaryWord.fromFirestore(doc))
          .toList();
    });
  }

  /// Consulta puntual de palabras desde 'glosario_a1'.
  Future<List<GlossaryWord>> getGlossaryWords({String? category}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('glosario_a1');
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        return (category != null && category.isNotEmpty)
            ? glossaryWords.where((w) => w.category == category).toList()
            : List<GlossaryWord>.from(glossaryWords);
      }

      return snapshot.docs
          .map((doc) => GlossaryWord.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[FirestoreService] Error al obtener glosario_a1: $e');
      return (category != null && category.isNotEmpty)
          ? glossaryWords.where((w) => w.category == category).toList()
          : List<GlossaryWord>.from(glossaryWords);
    }
  }

  /// Busca una palabra en 'glosario_a1' emparejando con etiquetas detectadas por IA.
  Future<GlossaryWord?> findWordByAiLabel(String label) async {
    try {
      final cleanLabel = GlossaryWord.normalize(label);
      if (cleanLabel.isEmpty) return null;
      debugPrint('[FirestoreService] Buscando por etiqueta IA: "$cleanLabel"');

      // 1. Consulta en 'glosario_a1' por etiquetasIA (arrayContains)
      final queryByTag = await _firestore
          .collection('glosario_a1')
          .where('etiquetasIA', arrayContains: cleanLabel)
          .limit(1)
          .get();

      if (queryByTag.docs.isNotEmpty) {
        return GlossaryWord.fromFirestore(queryByTag.docs.first);
      }

      // 2. Fallback: consulta por wordEn
      final queryByWord = await _firestore
          .collection('glosario_a1')
          .where('wordEn', isEqualTo: cleanLabel)
          .limit(1)
          .get();

      if (queryByWord.docs.isNotEmpty) {
        return GlossaryWord.fromFirestore(queryByWord.docs.first);
      }

      // 3. Fallback en catálogo local en memoria
      for (final word in glossaryWords) {
        if (word.matchesAiLabel(cleanLabel)) {
          return word;
        }
      }

      return null;
    } catch (e) {
      debugPrint('[FirestoreService] Error al buscar palabra por etiqueta IA: $e');
      for (final word in glossaryWords) {
        if (word.matchesAiLabel(label)) {
          return word;
        }
      }
      return null;
    }
  }

  /// Guarda o actualiza una palabra en la colección 'glosario_a1'.
  Future<void> saveGlossaryWord(GlossaryWord word) async {
    try {
      final docRef = _firestore.collection('glosario_a1').doc(word.id);
      await docRef.set(word.toFirestore(), SetOptions(merge: true));
      debugPrint('[FirestoreService] Palabra guardada en glosario_a1: ${word.wordEn}');
    } catch (e, stackTrace) {
      debugPrint('[FirestoreService] Error al guardar palabra en glosario_a1: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Sube y sincroniza el catálogo inicial A1 (102 palabras de [glossaryWords]) en 'glosario_a1'.
  /// Si la colección ya contiene documentos y [force] es false, omite la subida para evitar sobrecostos.
  /// Cada documento almacena la palabra en inglés, traducción en español, fonética,
  /// ejemplos bilingües, categoría y etiquetas para visión por IA.
  Future<int> subirGlosarioInicial({
    List<GlossaryWord>? initialWords,
    bool force = false,
  }) async {
    try {
      final collection = _firestore.collection('glosario_a1');
      if (!force) {
        final checkSnapshot = await collection.limit(1).get();
        if (checkSnapshot.docs.isNotEmpty) {
          debugPrint(
            '[FirestoreService] La colección glosario_a1 ya contiene datos. Omitiendo subida inicial.',
          );
          return 0;
        }
      }

      final wordsToSeed = initialWords ?? glossaryWords;
      debugPrint(
        '[FirestoreService] Subiendo ${wordsToSeed.length} palabras a la colección glosario_a1...',
      );

      const int batchLimit = 400;
      int totalSeeded = 0;

      for (int i = 0; i < wordsToSeed.length; i += batchLimit) {
        final batch = _firestore.batch();
        final chunk = wordsToSeed.skip(i).take(batchLimit);

        for (final word in chunk) {
          final docRef = collection.doc(word.id);
          batch.set(docRef, word.toFirestore(), SetOptions(merge: true));
          totalSeeded++;
        }

        await batch.commit();
      }

      debugPrint(
        '[FirestoreService] Glosario inicial subido con éxito: $totalSeeded palabras registradas en glosario_a1.',
      );
      return totalSeeded;
    } catch (e, stackTrace) {
      debugPrint('[FirestoreService] Error al subir glosario inicial a Firestore: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Alias de compatibilidad hacia [subirGlosarioInicial].
  Future<int> seedGlossaryIfEmpty({List<GlossaryWord>? initialWords}) =>
      subirGlosarioInicial(initialWords: initialWords);

  // ===========================================================================
  // MÉTODOS DE MÉTRICAS Y PROGRESO DEL PILOTO ('progreso_metricas')
  // ===========================================================================

  /// Registra un evento métrico cuantitativo en 'progreso_metricas/{userId}/eventos'.
  Future<void> recordPilotMetricEvent({
    required String userId,
    required String tipoEvento,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (userId.isEmpty) return;

      final data = {
        'userId': userId,
        'tipoEvento': tipoEvento,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('progreso_metricas')
          .doc(userId)
          .collection('eventos')
          .add(data);

      debugPrint(
        '[FirestoreService] Evento registrado en progreso_metricas: $tipoEvento para $userId',
      );
    } catch (e) {
      debugPrint(
        '[FirestoreService] Aviso: Error al registrar evento métrico: $e',
      );
    }
  }

  /// Sincroniza el resumen consolidado de métricas del estudiante en 'progreso_metricas/{userId}'.
  Future<void> syncProgressSummary({
    required String userId,
    required Map<String, dynamic> summaryJson,
  }) async {
    try {
      if (userId.isEmpty) return;

      final data = {
        ...summaryJson,
        'userId': userId,
        'ultimaSincronizacion': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('progreso_metricas')
          .doc(userId)
          .set(data, SetOptions(merge: true));

      debugPrint(
        '[FirestoreService] Resumen de progreso sincronizado en progreso_metricas para: $userId',
      );
    } catch (e) {
      debugPrint(
        '[FirestoreService] Error al sincronizar progreso_metricas: $e',
      );
    }
  }

  /// Stream reactivo de las métricas consolidadas del estudiante para paneles en tiempo real.
  Stream<Map<String, dynamic>?> streamProgressMetrics(String userId) {
    if (userId.isEmpty) return Stream.value(null);

    return _firestore
        .collection('progreso_metricas')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  /// Consulta puntual de las métricas consolidadas del estudiante.
  Future<Map<String, dynamic>?> getUserProgressMetrics(String userId) async {
    try {
      if (userId.isEmpty) return null;
      final doc =
          await _firestore.collection('progreso_metricas').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('[FirestoreService] Error al consultar progreso_metricas de $userId: $e');
      return null;
    }
  }

  /// Consulta todos los resúmenes de progreso de estudiantes en 'progreso_metricas'
  /// para el panel del Administrador.
  Future<List<Map<String, dynamic>>> getAllStudentProgressSummaries() async {
    try {
      final snapshot = await _firestore.collection('progreso_metricas').get();
      return snapshot.docs
          .map((doc) => {'userId': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('[FirestoreService] Error al consultar métricas del piloto: $e');
      return [];
    }
  }

  /// Stream reactivo de todos los registros de progreso de estudiantes para el Administrador.
  Stream<List<Map<String, dynamic>>> streamAllStudentProgressSummaries() {
    return _firestore.collection('progreso_metricas').snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => {'userId': doc.id, ...doc.data()}).toList(),
    );
  }
}
