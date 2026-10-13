import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';

/// Pantalla exclusiva para el Administrador que visualiza las métricas cuantitativas
/// consolidadas del piloto pedagógico de grado registradas en 'progreso_metricas'.
class AdminPilotMetricsScreen extends StatelessWidget {
  const AdminPilotMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas del Piloto'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService.instance.streamAllStudentProgressSummaries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error al cargar métricas del piloto: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final summaries = snapshot.data ?? [];

          // Cálculos acumulativos del piloto
          int totalWordsViewed = 0;
          int totalAudioPlays = 0;
          int totalPractices = 0;
          int totalCameraUses = 0;
          int totalCorrect = 0;
          int totalIncorrect = 0;

          for (final item in summaries) {
            totalWordsViewed += (item['wordsViewed'] as num? ?? 0).toInt();
            totalAudioPlays += (item['audioPlays'] as num? ?? 0).toInt();
            totalPractices += (item['practiceCompleted'] as num? ?? 0).toInt();
            totalCameraUses += (item['cameraUses'] as num? ?? 0).toInt();
            totalCorrect += (item['correctAnswers'] as num? ?? 0).toInt();
            totalIncorrect += (item['incorrectAnswers'] as num? ?? 0).toInt();
          }

          final totalQuestions = totalCorrect + totalIncorrect;
          final avgSuccessRate = totalQuestions > 0
              ? (totalCorrect / totalQuestions) * 100
              : 0.0;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // Tarjeta Resumen General
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.analytics_rounded,
                              color: AppTheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Consolidado del Piloto',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Telemetría de estudiantes en tiempo real',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Estudiantes Activos',
                              value: '${summaries.length}',
                              icon: Icons.people_alt_rounded,
                              color: Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _MetricTile(
                              label: 'Tasa Acierto Global',
                              value: '${avgSuccessRate.toStringAsFixed(1)}%',
                              icon: Icons.check_circle_rounded,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Palabras Vistas',
                              value: '$totalWordsViewed',
                              icon: Icons.menu_book_rounded,
                              color: Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: _MetricTile(
                              label: 'Audios TTS',
                              value: '$totalAudioPlays',
                              icon: Icons.volume_up_rounded,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Prácticas Hechas',
                              value: '$totalPractices',
                              icon: Icons.quiz_rounded,
                              color: Colors.teal,
                            ),
                          ),
                          Expanded(
                            child: _MetricTile(
                              label: 'Usos de Cámara',
                              value: '$totalCameraUses',
                              icon: Icons.camera_alt_rounded,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Desglose por Estudiante',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              if (summaries.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Aún no hay registros en "progreso_metricas"',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Cuando los estudiantes completen lecciones o exploren con la cámara, sus datos se sincronizarán automáticamente aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...summaries.map((item) {
                  final uid = item['userId']?.toString() ?? 'UID Desconocido';
                  final words = item['wordsViewed'] ?? 0;
                  final audios = item['audioPlays'] ?? 0;
                  final correct = item['correctAnswers'] ?? 0;
                  final incorrect = item['incorrectAnswers'] ?? 0;
                  final lastAccess = item['lastAccess']?.toString() ?? 'N/A';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      title: Text(
                        'Estudiante: ${uid.length > 12 ? uid.substring(0, 12) : uid}...',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Palabras: $words | Audios: $audios | Aciertos: $correct | Fallos: $incorrect\nÚltimo acceso: $lastAccess',
                          style: const TextStyle(height: 1.35, fontSize: 13),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
