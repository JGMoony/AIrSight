import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/haptic_service.dart';
import '../../services/metrics_export_service.dart';
import 'admin_student_detail_screen.dart';

/// Pantalla exclusiva para el Administrador que visualiza las métricas cuantitativas
/// consolidadas del piloto pedagógico de grado registradas en 'progreso_metricas'.
/// Incluye desglose por estudiante con resolución de nombres y navegación a detalle.
class AdminPilotMetricsScreen extends StatelessWidget {
  const AdminPilotMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService.instance.streamAllUsers(),
      builder: (context, userSnapshot) {
        final usersList = userSnapshot.data ?? [];
        final usersMap = {for (final u in usersList) u.uid: u};

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService.instance.streamAllStudentProgressSummaries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(title: const Text('Métricas del Piloto')),
                body: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Métricas del Piloto')),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error al cargar métricas del piloto: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
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

              return Scaffold(
                appBar: AppBar(
                  title: const Text('Métricas del Piloto'),
                  actions: [
                    if (summaries.isNotEmpty) ...[
                      Semantics(
                        label: 'Exportar consolidado global a archivo CSV, botón',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.table_chart_rounded),
                          tooltip: 'Exportar CSV Global',
                          onPressed: () async {
                            final csv = MetricsExportService.generateGlobalCsv(summaries, usersMap);
                            await MetricsExportService.exportAndShareCsv(
                              context: context,
                              title: 'Air Sight - Consolidado Global (CSV)',
                              fileName: 'reporte_global_airsight',
                              csvContent: csv,
                            );
                          },
                        ),
                      ),
                      Semantics(
                        label: 'Exportar consolidado global a archivo PDF, botón',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          tooltip: 'Exportar PDF Global',
                          onPressed: () async {
                            final pdfBytes = await MetricsExportService.generateGlobalPdf(
                              summaries: summaries,
                              usersMap: usersMap,
                            );
                            if (context.mounted) {
                              await MetricsExportService.exportAndSharePdf(
                                context: context,
                                title: 'Air Sight - Reporte Global PDF',
                                fileName: 'reporte_global_airsight',
                                pdfBytes: pdfBytes,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                body: ListView(
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
                                    label: 'Palabras Vistas',
                                    value: '$totalWordsViewed',
                                    icon: Icons.menu_book_rounded,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                                Expanded(
                                  child: _MetricTile(
                                    label: 'Audios TTS',
                                    value: '$totalAudioPlays',
                                    icon: Icons.volume_up_rounded,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricTile(
                                    label: 'Prácticas',
                                    value: '$totalPractices',
                                    icon: Icons.assignment_turned_in_rounded,
                                    color: const Color(0xFF7C3AED),
                                  ),
                                ),
                                Expanded(
                                  child: _MetricTile(
                                    label: 'Cámara IA',
                                    value: '$totalCameraUses',
                                    icon: Icons.camera_alt_rounded,
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricTile(
                                    label: 'Aciertos',
                                    value: '$totalCorrect',
                                    icon: Icons.check_circle_rounded,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                Expanded(
                                  child: _MetricTile(
                                    label: 'Fallos',
                                    value: '$totalIncorrect',
                                    icon: Icons.cancel_rounded,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.insights_rounded,
                                    color: AppTheme.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Tasa Global de Aciertos:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${avgSuccessRate.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Botones accesibles de exportación (CSV y PDF)
                            Row(
                              children: [
                                Expanded(
                                  child: Semantics(
                                    label: 'Exportar reporte global en formato tabular CSV, botón',
                                    button: true,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primary,
                                        side: const BorderSide(color: AppTheme.primary, width: 1.5),
                                        minimumSize: const Size(0, 48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      ),
                                      onPressed: () async {
                                        final csv = MetricsExportService.generateGlobalCsv(summaries, usersMap);
                                        await MetricsExportService.exportAndShareCsv(
                                          context: context,
                                          title: 'Air Sight - Consolidado Global (CSV)',
                                          fileName: 'reporte_global_airsight',
                                          csvContent: csv,
                                        );
                                      },
                                      icon: const Icon(Icons.table_chart_rounded, size: 20),
                                      label: const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Exportar CSV',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Semantics(
                                    label: 'Exportar reporte global en formato estructurado PDF, botón',
                                    button: true,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        minimumSize: const Size(0, 48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      ),
                                      onPressed: () async {
                                        final pdfBytes = await MetricsExportService.generateGlobalPdf(
                                          summaries: summaries,
                                          usersMap: usersMap,
                                        );
                                        if (context.mounted) {
                                          await MetricsExportService.exportAndSharePdf(
                                            context: context,
                                            title: 'Air Sight - Reporte Global PDF',
                                            fileName: 'reporte_global_airsight',
                                            pdfBytes: pdfBytes,
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                                      label: const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Exportar PDF',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Sección: Desglose por Estudiante
                  Semantics(
                    header: true,
                    child: const Text(
                      'Desglose por Estudiante',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (summaries.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
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
                      final user = usersMap[uid];
                      final studentName = (user != null && user.nombre.trim().isNotEmpty)
                          ? user.nombre.trim()
                          : (user?.email.isNotEmpty == true
                              ? user!.email
                              : 'Estudiante (${uid.length > 8 ? uid.substring(0, 8) : uid})');
                      final studentEmail = user?.email ?? '';

                      final words = item['wordsViewed'] ?? 0;
                      final audios = item['audioPlays'] ?? 0;
                      final correct = item['correctAnswers'] ?? 0;
                      final incorrect = item['incorrectAnswers'] ?? 0;
                      final lastAccess = item['lastAccess']?.toString() ?? 'N/A';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            HapticService.selection();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminStudentDetailScreen(
                                  userId: uid,
                                  studentName: studentName,
                                  studentEmail: studentEmail,
                                  metrics: item,
                                ),
                              ),
                            );
                          },
                          child: Semantics(
                            label:
                                'Estudiante $studentName. Palabras: $words, audios: $audios, aciertos: $correct, fallos: $incorrect. Toca dos veces para ver métricas detalladas.',
                            button: true,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: AppTheme.primary,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          studentName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        if (studentEmail.isNotEmpty && studentEmail != studentName) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            studentEmail,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                          'Palabras: $words | Audios: $audios | Aciertos: $correct | Fallos: $incorrect\nÚltimo acceso: $lastAccess',
                                          style: const TextStyle(height: 1.35, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppTheme.primary,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
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
