import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firestore_service.dart';

class ProgressSummary {
  final int wordsViewed;
  final int audioPlays;
  final int practiceCompleted;
  final int cameraUses;
  final int correctAnswers;
  final int incorrectAnswers;
  final int tutorQueries;
  final double successRate;
  final String lastAccess;

  const ProgressSummary({
    required this.wordsViewed,
    required this.audioPlays,
    required this.practiceCompleted,
    required this.cameraUses,
    required this.correctAnswers,
    required this.incorrectAnswers,
    this.tutorQueries = 0,
    required this.successRate,
    required this.lastAccess,
  });

  factory ProgressSummary.empty() {
    return const ProgressSummary(
      wordsViewed: 0,
      audioPlays: 0,
      practiceCompleted: 0,
      cameraUses: 0,
      correctAnswers: 0,
      incorrectAnswers: 0,
      tutorQueries: 0,
      successRate: 0.0,
      lastAccess: '',
    );
  }

  ProgressSummary copyWith({
    int? wordsViewed,
    int? audioPlays,
    int? practiceCompleted,
    int? cameraUses,
    int? correctAnswers,
    int? incorrectAnswers,
    int? tutorQueries,
    double? successRate,
    String? lastAccess,
  }) {
    return ProgressSummary(
      wordsViewed: wordsViewed ?? this.wordsViewed,
      audioPlays: audioPlays ?? this.audioPlays,
      practiceCompleted: practiceCompleted ?? this.practiceCompleted,
      cameraUses: cameraUses ?? this.cameraUses,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
      tutorQueries: tutorQueries ?? this.tutorQueries,
      successRate: successRate ?? this.successRate,
      lastAccess: lastAccess ?? this.lastAccess,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wordsViewed': wordsViewed,
      'audioPlays': audioPlays,
      'practiceCompleted': practiceCompleted,
      'cameraUses': cameraUses,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'tutorQueries': tutorQueries,
      'lastAccess': lastAccess,
    };
  }

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    final correctAnswers = json['correctAnswers'] ?? 0;
    final incorrectAnswers = json['incorrectAnswers'] ?? 0;
    final totalAnswers = correctAnswers + incorrectAnswers;

    return ProgressSummary(
      wordsViewed: json['wordsViewed'] ?? 0,
      audioPlays: json['audioPlays'] ?? 0,
      practiceCompleted: json['practiceCompleted'] ?? 0,
      cameraUses: json['cameraUses'] ?? 0,
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      tutorQueries: json['tutorQueries'] ?? 0,
      successRate: totalAnswers == 0 ? 0.0 : correctAnswers / totalAnswers,
      lastAccess: json['lastAccess'] ?? '',
    );
  }
}

class ProgressService {
  static bool get _isTest {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  static String _userKey([String? uid]) {
    final currentUid = uid ?? _safeCurrentUser?.uid;
    if (currentUid != null && currentUid.isNotEmpty) {
      return 'progress_summary_$currentUid';
    }
    return 'progress_summary_guest';
  }

  static Future<ProgressSummary> getSummary() async {
    final currentUser = _safeCurrentUser;
    final currentUid = currentUser?.uid;
    final key = _userKey(currentUid);

    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(key);

    if (rawData != null) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) {
          return ProgressSummary.fromJson(decoded);
        }
      } catch (_) {}
    }

    // Si no hay datos en caché local pero hay usuario autenticado, cargar de Firestore (progreso_metricas)
    if (!_isTest && currentUid != null && currentUid.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('progreso_metricas')
            .doc(currentUid)
            .get();

        if (doc.exists && doc.data() != null) {
          final summary = ProgressSummary.fromJson(doc.data()!);
          await prefs.setString(key, jsonEncode(summary.toJson()));
          return summary;
        }
      } catch (e) {
        debugPrint('[ProgressService] Error consultando progreso_metricas de Firestore: $e');
      }
    }

    return ProgressSummary.empty();
  }

  static Future<void> _saveSummary(ProgressSummary summary) async {
    final currentUser = _safeCurrentUser;
    final currentUid = currentUser?.uid;
    final key = _userKey(currentUid);

    final prefs = await SharedPreferences.getInstance();

    final updatedSummary = summary.copyWith(
      lastAccess: DateTime.now().toString().substring(0, 16),
    );

    await prefs.setString(
      key,
      jsonEncode(updatedSummary.toJson()),
    );

    // Sincronización estricta por usuario en Firestore (progreso_metricas/{uid})
    if (!_isTest && currentUid != null && currentUid.isNotEmpty) {
      try {
        final data = {
          ...updatedSummary.toJson(),
          'usuarioId': currentUid,
          'userId': currentUid,
          'ultimaActualizacion': FieldValue.serverTimestamp(),
          'ultimaSincronizacion': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('progreso_metricas')
            .doc(currentUid)
            .set(data, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[ProgressService] Error sincronizando progreso_metricas con Firestore: $e');
      }
    }
  }

  static User? get _safeCurrentUser {
    if (_isTest) return null;
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Registra una palabra vista.
  /// El parámetro wordId es opcional para mantener compatibilidad con llamadas existentes.
  static Future<void> registerWordViewed([String? wordId]) async {
    final current = await getSummary();

    await _saveSummary(
      current.copyWith(
        wordsViewed: current.wordsViewed + 1,
      ),
    );

    final currentUser = _safeCurrentUser;
    if (currentUser != null) {
      FirestoreService.instance.recordPilotMetricEvent(
        userId: currentUser.uid,
        tipoEvento: 'word_view',
        metadata: wordId != null ? {'wordId': wordId} : null,
      );
    }
  }

  /// Registra reproducción de audio.
  /// Este nombre coincide con lo que ya usa tu app.
  static Future<void> registerAudioPlay() async {
    final current = await getSummary();

    await _saveSummary(
      current.copyWith(
        audioPlays: current.audioPlays + 1,
      ),
    );

    final currentUser = _safeCurrentUser;
    if (currentUser != null) {
      FirestoreService.instance.recordPilotMetricEvent(
        userId: currentUser.uid,
        tipoEvento: 'audio_play',
      );
    }
  }

  /// Alias por si luego usas este otro nombre.
  static Future<void> registerAudioPlayed() async {
    await registerAudioPlay();
  }

  static Future<void> registerCameraUse() async {
    final current = await getSummary();

    await _saveSummary(
      current.copyWith(
        cameraUses: current.cameraUses + 1,
      ),
    );

    final currentUser = _safeCurrentUser;
    if (currentUser != null) {
      FirestoreService.instance.recordPilotMetricEvent(
        userId: currentUser.uid,
        tipoEvento: 'camera_use',
      );
    }
  }

  static Future<void> registerTutorQuery() async {
    final current = await getSummary();

    await _saveSummary(
      current.copyWith(
        tutorQueries: current.tutorQueries + 1,
      ),
    );

    final currentUser = _safeCurrentUser;
    if (currentUser != null) {
      FirestoreService.instance.recordPilotMetricEvent(
        userId: currentUser.uid,
        tipoEvento: 'tutor_query',
      );
    }
  }

  static Future<void> registerPracticeAnswer({
    required bool isCorrect,
  }) async {
    final current = await getSummary();

    await _saveSummary(
      current.copyWith(
        practiceCompleted: current.practiceCompleted + 1,
        correctAnswers:
            isCorrect ? current.correctAnswers + 1 : current.correctAnswers,
        incorrectAnswers:
            isCorrect ? current.incorrectAnswers : current.incorrectAnswers + 1,
      ),
    );

    final currentUser = _safeCurrentUser;
    if (currentUser != null) {
      FirestoreService.instance.recordPilotMetricEvent(
        userId: currentUser.uid,
        tipoEvento: 'practice_answer',
        metadata: {'isCorrect': isCorrect},
      );
    }
  }

  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_userKey());
  }
}