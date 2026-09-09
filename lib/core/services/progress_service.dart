import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ProgressSummary {
  final int wordsViewed;
  final int audioPlays;
  final int practiceCompleted;
  final int cameraUses;
  final int correctAnswers;
  final int incorrectAnswers;
  final double successRate;
  final String lastAccess;

  const ProgressSummary({
    required this.wordsViewed,
    required this.audioPlays,
    required this.practiceCompleted,
    required this.cameraUses,
    required this.correctAnswers,
    required this.incorrectAnswers,
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
      successRate: totalAnswers == 0 ? 0.0 : correctAnswers / totalAnswers,
      lastAccess: json['lastAccess'] ?? '',
    );
  }
}

class ProgressService {
  static const String _progressKey = 'progress_summary';

  static Future<ProgressSummary> getSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_progressKey);

    if (rawData == null) {
      return ProgressSummary.empty();
    }

    final decoded = jsonDecode(rawData);

    if (decoded is! Map<String, dynamic>) {
      return ProgressSummary.empty();
    }

    return ProgressSummary.fromJson(decoded);
  }

  static Future<void> _saveSummary(ProgressSummary summary) async {
    final prefs = await SharedPreferences.getInstance();

    final updatedSummary = summary.copyWith(
      lastAccess: DateTime.now().toString().substring(0, 16),
    );

    await prefs.setString(
      _progressKey,
      jsonEncode(updatedSummary.toJson()),
    );
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
  }

  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_progressKey);
  }
}