import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/metrics_export_service.dart';

/// Pantalla accesible de detalle pedagógico individual de un estudiante (Módulo Admin).
/// Permite al docente/administrador inspeccionar métricas cuantitativas específicas
/// (consultas al glosario, prácticas completadas, aciertos, fallos y última sesión).
class AdminStudentDetailScreen extends StatelessWidget {
  final String userId;
  final String studentName;
  final String studentEmail;
  final Map<String, dynamic> metrics;

  const AdminStudentDetailScreen({
    super.key,
    required this.userId,
    required this.studentName,
    required this.studentEmail,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final wordsViewed = (metrics['wordsViewed'] as num? ?? 0).toInt();
    final audioPlays = (metrics['audioPlays'] as num? ?? 0).toInt();
    final practiceCompleted = (metrics['practiceCompleted'] as num? ?? 0).toInt();
    final cameraUses = (metrics['cameraUses'] as num? ?? 0).toInt();
    final correctAnswers = (metrics['correctAnswers'] as num? ?? 0).toInt();
    final incorrectAnswers = (metrics['incorrectAnswers'] as num? ?? 0).toInt();
    final lastAccess = metrics['lastAccess']?.toString() ?? 'Sin registro';

    final totalQuestions = correctAnswers + incorrectAnswers;
    final accuracy = totalQuestions > 0
        ? ((correctAnswers / totalQuestions) * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Estudiante'),
        leading: Semantics(
          label: 'Regresar a métricas del piloto, botón',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Regresar',
            onPressed: () {
              HapticService.selection();
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          Semantics(
            label: 'Exportar métricas de este estudiante a archivo CSV, botón',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.table_chart_rounded),
              tooltip: 'Exportar CSV',
              onPressed: () async {
                final csv = MetricsExportService.generateStudentCsv(
                  studentName: studentName,
                  studentEmail: studentEmail,
                  userId: userId,
                  metrics: metrics,
                );
                await MetricsExportService.exportAndShareCsv(
                  context: context,
                  title: 'Air Sight - Reporte Estudiante: $studentName (CSV)',
                  fileName: 'estudiante_${userId}_metricas',
                  csvContent: csv,
                );
              },
            ),
          ),
          Semantics(
            label: 'Exportar reporte de este estudiante a archivo PDF, botón',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Exportar PDF',
              onPressed: () async {
                final pdfBytes = await MetricsExportService.generateStudentPdf(
                  studentName: studentName,
                  studentEmail: studentEmail,
                  userId: userId,
                  metrics: metrics,
                );
                if (context.mounted) {
                  await MetricsExportService.exportAndSharePdf(
                    context: context,
                    title: 'Air Sight - Reporte Estudiante: $studentName (PDF)',
                    fileName: 'estudiante_${userId}_reporte',
                    pdfBytes: pdfBytes,
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Tarjeta de Identificación del Estudiante
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppTheme.primary,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName.isNotEmpty ? studentName : 'Estudiante sin nombre',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                studentEmail.isNotEmpty ? studentEmail : 'UID: $userId',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Rol: Estudiante',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    // Botones accesibles de exportación (CSV y PDF)
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            label: 'Exportar datos del estudiante a archivo CSV, botón',
                            button: true,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                side: const BorderSide(color: AppTheme.primary, width: 1.5),
                                minimumSize: const Size(0, 44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                              onPressed: () async {
                                final csv = MetricsExportService.generateStudentCsv(
                                  studentName: studentName,
                                  studentEmail: studentEmail,
                                  userId: userId,
                                  metrics: metrics,
                                );
                                await MetricsExportService.exportAndShareCsv(
                                  context: context,
                                  title: 'Air Sight - Reporte: $studentName (CSV)',
                                  fileName: 'estudiante_${userId}_metricas',
                                  csvContent: csv,
                                );
                              },
                              icon: const Icon(Icons.table_chart_rounded, size: 18),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Exportar CSV',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Semantics(
                            label: 'Exportar reporte del estudiante a archivo PDF, botón',
                            button: true,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                minimumSize: const Size(0, 44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                              onPressed: () async {
                                final pdfBytes = await MetricsExportService.generateStudentPdf(
                                  studentName: studentName,
                                  studentEmail: studentEmail,
                                  userId: userId,
                                  metrics: metrics,
                                );
                                if (context.mounted) {
                                  await MetricsExportService.exportAndSharePdf(
                                    context: context,
                                    title: 'Air Sight - Reporte: $studentName (PDF)',
                                    fileName: 'estudiante_${userId}_reporte',
                                    pdfBytes: pdfBytes,
                                  );
                                }
                              },
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Exportar PDF',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
            const SizedBox(height: 20),

            // Encabezado de Métricas
            Semantics(
              header: true,
              child: const Text(
                'Métricas Cuantitativas de Aprendizaje',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filas de Métricas en Cuadrícula
            Row(
              children: [
                Expanded(
                  child: _DetailMetricCard(
                    title: 'Palabras Vistas',
                    value: '$wordsViewed',
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF2563EB),
                    semanticDescription: 'Palabras consultadas en el glosario: $wordsViewed',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailMetricCard(
                    title: 'Audios TTS',
                    value: '$audioPlays',
                    icon: Icons.volume_up_rounded,
                    color: const Color(0xFF059669),
                    semanticDescription: 'Reproducciones de audio en inglés: $audioPlays',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DetailMetricCard(
                    title: 'Prácticas',
                    value: '$practiceCompleted',
                    icon: Icons.assignment_turned_in_rounded,
                    color: const Color(0xFF7C3AED),
                    semanticDescription: 'Sesiones de práctica completadas: $practiceCompleted',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailMetricCard(
                    title: 'Cámara IA',
                    value: '$cameraUses',
                    icon: Icons.camera_alt_rounded,
                    color: const Color(0xFFD97706),
                    semanticDescription: 'Objetos identificados con visión artificial: $cameraUses',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DetailMetricCard(
                    title: 'Aciertos',
                    value: '$correctAnswers',
                    icon: Icons.check_circle_rounded,
                    color: Colors.green.shade700,
                    semanticDescription: 'Respuestas correctas: $correctAnswers',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailMetricCard(
                    title: 'Fallos',
                    value: '$incorrectAnswers',
                    icon: Icons.cancel_rounded,
                    color: Colors.red.shade700,
                    semanticDescription: 'Respuestas incorrectas: $incorrectAnswers',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tarjeta de Precisión y Desempeño
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed_rounded, color: AppTheme.primary),
                        const SizedBox(width: 10),
                        const Text(
                          'Eficacia de Respuestas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$accuracy%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: totalQuestions > 0 ? (correctAnswers / totalQuestions) : 0,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade300,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Preguntas totales respondidas: $totalQuestions ($correctAnswers aciertos, $incorrectAnswers fallos)',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta de Última Sesión
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time_filled_rounded, color: Colors.blueGrey),
                ),
                title: const Text(
                  'Última Actividad Registrada',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Text(
                  lastAccess,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String semanticDescription;

  const _DetailMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.semanticDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticDescription,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
