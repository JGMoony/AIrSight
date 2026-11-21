import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_theme.dart';
import '../models/user_model.dart';
import 'haptic_service.dart';

/// Servicio accesible de exportación de métricas pedagógicas del piloto (Módulo Admin).
/// Permite generar y exportar datos tabulares limpios en formato CSV y reportes estructurados
/// en PDF con soporte para compartir nativo (share_plus), guardado y previsualización.
class MetricsExportService {
  MetricsExportService._();

  /// Genera una cadena CSV con el consolidado global de todos los estudiantes del piloto.
  static String generateGlobalCsv(
    List<Map<String, dynamic>> summaries,
    Map<String, UserModel> usersMap,
  ) {
    final buffer = StringBuffer();

    // Encabezados estándar CSV
    buffer.writeln(
      '"Estudiante","Email","UID","Palabras Exploradas","Reproducciones Audio",'
      '"Practicas Completadas","Usos Camara","Aciertos","Fallos","Precision (%)","Ultimo Acceso"',
    );

    int totalWords = 0;
    int totalAudios = 0;
    int totalPractices = 0;
    int totalCameras = 0;
    int totalCorrect = 0;
    int totalIncorrect = 0;

    for (final item in summaries) {
      final uid = item['userId']?.toString() ?? '';
      final user = usersMap[uid];

      final studentName = user?.name.isNotEmpty == true
          ? user!.name
          : (item['studentName']?.toString() ?? 'Estudiante');
      final studentEmail = user?.email.isNotEmpty == true
          ? user!.email
          : (item['studentEmail']?.toString() ?? 'Sin correo');

      final words = (item['wordsViewed'] as num? ?? 0).toInt();
      final audios = (item['audioPlays'] as num? ?? 0).toInt();
      final practices = (item['practiceCompleted'] as num? ?? 0).toInt();
      final camera = (item['cameraUses'] as num? ?? 0).toInt();
      final correct = (item['correctAnswers'] as num? ?? 0).toInt();
      final incorrect = (item['incorrectAnswers'] as num? ?? 0).toInt();
      final lastAccess = item['lastAccess']?.toString() ?? 'Sin registro';

      totalWords += words;
      totalAudios += audios;
      totalPractices += practices;
      totalCameras += camera;
      totalCorrect += correct;
      totalIncorrect += incorrect;

      final questions = correct + incorrect;
      final acc = questions > 0
          ? ((correct / questions) * 100).toStringAsFixed(1)
          : '0.0';

      buffer.writeln(
        '"${_escapeCsv(studentName)}","${_escapeCsv(studentEmail)}","${_escapeCsv(uid)}",'
        '$words,$audios,$practices,$camera,$correct,$incorrect,"$acc%","$lastAccess"',
      );
    }

    // Fila de totales acumulados del piloto
    final totalQ = totalCorrect + totalIncorrect;
    final globalAcc = totalQ > 0
        ? ((totalCorrect / totalQ) * 100).toStringAsFixed(1)
        : '0.0';

    buffer.writeln(
      '"TOTALES PILOTO","","",$totalWords,$totalAudios,$totalPractices,'
      '$totalCameras,$totalCorrect,$totalIncorrect,"$globalAcc%",""',
    );

    return buffer.toString();
  }

  /// Genera una cadena CSV con las métricas cuantitativas individuales de un estudiante.
  static String generateStudentCsv({
    required String studentName,
    required String studentEmail,
    required String userId,
    required Map<String, dynamic> metrics,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('"Metrica","Valor"');

    final words = (metrics['wordsViewed'] as num? ?? 0).toInt();
    final audios = (metrics['audioPlays'] as num? ?? 0).toInt();
    final practices = (metrics['practiceCompleted'] as num? ?? 0).toInt();
    final camera = (metrics['cameraUses'] as num? ?? 0).toInt();
    final correct = (metrics['correctAnswers'] as num? ?? 0).toInt();
    final incorrect = (metrics['incorrectAnswers'] as num? ?? 0).toInt();
    final lastAccess = metrics['lastAccess']?.toString() ?? 'Sin registro';

    final totalQuestions = correct + incorrect;
    final accuracy = totalQuestions > 0
        ? ((correct / totalQuestions) * 100).toStringAsFixed(1)
        : '0.0';

    buffer.writeln('"Estudiante","${_escapeCsv(studentName)}"');
    buffer.writeln('"Email","${_escapeCsv(studentEmail)}"');
    buffer.writeln('"UID","${_escapeCsv(userId)}"');
    buffer.writeln('"Palabras Exploradas","$words"');
    buffer.writeln('"Reproducciones de Audio","$audios"');
    buffer.writeln('"Practicas Completadas","$practices"');
    buffer.writeln('"Usos de Camara","$camera"');
    buffer.writeln('"Respuestas Correctas","$correct"');
    buffer.writeln('"Respuestas Incorrectas","$incorrect"');
    buffer.writeln('"Precision","$accuracy%"');
    buffer.writeln('"Ultimo Acceso","${_escapeCsv(lastAccess)}"');

    return buffer.toString();
  }

  /// Genera un documento PDF formal, accesible y estructurado con el consolidado global de métricas.
  static Future<Uint8List> generateGlobalPdf({
    required List<Map<String, dynamic>> summaries,
    required Map<String, UserModel> usersMap,
  }) async {
    final pdf = pw.Document();

    int totalWords = 0;
    int totalAudios = 0;
    int totalPractices = 0;
    int totalCameras = 0;
    int totalCorrect = 0;
    int totalIncorrect = 0;

    final tableData = <List<String>>[];

    for (final item in summaries) {
      final uid = item['userId']?.toString() ?? '';
      final user = usersMap[uid];

      final studentName = user?.name.isNotEmpty == true
          ? user!.name
          : (item['studentName']?.toString() ?? 'Estudiante');
      final studentEmail = user?.email.isNotEmpty == true
          ? user!.email
          : (item['studentEmail']?.toString() ?? 'Sin correo');

      final words = (item['wordsViewed'] as num? ?? 0).toInt();
      final audios = (item['audioPlays'] as num? ?? 0).toInt();
      final practices = (item['practiceCompleted'] as num? ?? 0).toInt();
      final camera = (item['cameraUses'] as num? ?? 0).toInt();
      final correct = (item['correctAnswers'] as num? ?? 0).toInt();
      final incorrect = (item['incorrectAnswers'] as num? ?? 0).toInt();

      totalWords += words;
      totalAudios += audios;
      totalPractices += practices;
      totalCameras += camera;
      totalCorrect += correct;
      totalIncorrect += incorrect;

      final questions = correct + incorrect;
      final acc = questions > 0
          ? ((correct / questions) * 100).toStringAsFixed(1)
          : '0.0';

      tableData.add([
        studentName,
        studentEmail,
        '$words',
        '$audios',
        '$practices',
        '$camera',
        '$correct',
        '$incorrect',
        '$acc%',
      ]);
    }

    final totalQ = totalCorrect + totalIncorrect;
    final globalAcc = totalQ > 0
        ? ((totalCorrect / totalQ) * 100).toStringAsFixed(1)
        : '0.0';

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // Cabecera institucional
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Air Sight - Reporte de Métricas del Piloto',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Telemetría de aprendizaje y accesibilidad (Inglés A1)',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Fecha: $dateStr',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Divider(color: PdfColors.indigo300),
            pw.SizedBox(height: 12),

            // Resumen de Métricas
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pdfSummaryItem('Estudiantes', '${summaries.length}'),
                  _pdfSummaryItem('Palabras Vistas', '$totalWords'),
                  _pdfSummaryItem('Audios TTS', '$totalAudios'),
                  _pdfSummaryItem('Prácticas', '$totalPractices'),
                  _pdfSummaryItem('Cámara IA', '$totalCameras'),
                  _pdfSummaryItem('Aciertos', '$totalCorrect'),
                  _pdfSummaryItem('Fallos', '$totalIncorrect'),
                  _pdfSummaryItem('Precisión Global', '$globalAcc%'),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // Título de la tabla
            pw.Text(
              'Desglose Individual por Estudiante',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 8),

            // Tabla de datos
            pw.TableHelper.fromTextArray(
              headers: [
                'Estudiante',
                'Correo',
                'Palabras',
                'Audios',
                'Prácticas',
                'Cámara',
                'Aciertos',
                'Fallos',
                'Precisión',
              ],
              data: tableData,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.indigo700),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
                7: pw.Alignment.center,
                8: pw.Alignment.center,
              },
              border: pw.TableBorder.all(color: PdfColors.grey300),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            ),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Generado automáticamente por Air Sight • Cumplimiento WCAG 2.2 AA',
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Genera un documento PDF estructurado para un estudiante individual.
  static Future<Uint8List> generateStudentPdf({
    required String studentName,
    required String studentEmail,
    required String userId,
    required Map<String, dynamic> metrics,
  }) async {
    final pdf = pw.Document();

    final words = (metrics['wordsViewed'] as num? ?? 0).toInt();
    final audios = (metrics['audioPlays'] as num? ?? 0).toInt();
    final practices = (metrics['practiceCompleted'] as num? ?? 0).toInt();
    final camera = (metrics['cameraUses'] as num? ?? 0).toInt();
    final correct = (metrics['correctAnswers'] as num? ?? 0).toInt();
    final incorrect = (metrics['incorrectAnswers'] as num? ?? 0).toInt();
    final lastAccess = metrics['lastAccess']?.toString() ?? 'Sin registro';

    final totalQuestions = correct + incorrect;
    final accuracy = totalQuestions > 0
        ? ((correct / totalQuestions) * 100).toStringAsFixed(1)
        : '0.0';

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Air Sight - Reporte Individual de Estudiante',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Métricas cuantitativas de aprendizaje y participación',
                style:
                    const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.indigo300),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Estudiante: $studentName',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('Correo: $studentEmail',
                        style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('UID: $userId',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600)),
                    pw.Text('Fecha de emisión: $dateStr',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600)),
                    pw.Text('Última actividad: $lastAccess',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Resumen de Desempeño',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Métrica Pedagógica', 'Valor Registrado'],
                data: [
                  ['Palabras Exploradas en Glosario', '$words'],
                  ['Reproducciones de Audio y Fonética', '$audios'],
                  ['Sesiones de Práctica Completadas', '$practices'],
                  ['Interacciones con Cámara IA', '$camera'],
                  ['Respuestas Correctas', '$correct'],
                  ['Respuestas Incorrectas / Repasos', '$incorrect'],
                  ['Tasa Global de Precisión', '$accuracy%'],
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.indigo700),
                cellStyle: const pw.TextStyle(fontSize: 10),
                border: pw.TableBorder.all(color: PdfColors.grey300),
              ),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Air Sight • Proyecto de Grado • Accesibilidad WCAG 2.2 AA',
                  style:
                      const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Exporta y comparte el archivo CSV a través de las opciones nativas del dispositivo (share_plus).
  /// Si el diálogo nativo no responde o falla, ofrece fallback accesible al portapapeles.
  static Future<void> exportAndShareCsv({
    required BuildContext context,
    required String title,
    required String fileName,
    required String csvContent,
  }) async {
    await HapticService.buttonPress();
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName.csv');
      await file.writeAsString(csvContent, flush: true);

      await HapticService.success();
      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv', name: '$fileName.csv')],
        text: title,
      );

      if (context.mounted && result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Archivo CSV compartido exitosamente!'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        showExportDialog(
          context: context,
          title: title,
          csvContent: csvContent,
        );
      }
    }
  }

  /// Exporta y comparte el reporte PDF a través de las opciones nativas del dispositivo (share_plus).
  static Future<void> exportAndSharePdf({
    required BuildContext context,
    required String title,
    required String fileName,
    required Uint8List pdfBytes,
  }) async {
    await HapticService.buttonPress();
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName.pdf');
      await file.writeAsBytes(pdfBytes, flush: true);

      await HapticService.success();
      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: '$fileName.pdf')],
        text: title,
      );

      if (context.mounted && result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reporte PDF compartido exitosamente!'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo compartir el archivo PDF: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  static pw.Widget _pdfSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo900,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  /// Muestra un modal accesible con previsualización del CSV y copia automática al portapapeles.
  static Future<void> showExportDialog({
    required BuildContext context,
    required String title,
    required String csvContent,
  }) async {
    await HapticService.success();
    await Clipboard.setData(ClipboardData(text: csvContent));

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¡El reporte en formato CSV ha sido copiado automáticamente a tu portapapeles!\n\n'
              'Puedes pegarlo directamente en Excel, Google Sheets o enviarlo por correo.',
              style: TextStyle(height: 1.4, fontSize: 14),
            ),
            const SizedBox(height: 14),
            const Text(
              'Vista previa del archivo CSV:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              constraints: const BoxConstraints(maxHeight: 140),
              child: SingleChildScrollView(
                child: Text(
                  csvContent,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticService.selection();
              Navigator.pop(ctx);
            },
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(120, 44),
            ),
            onPressed: () async {
              await HapticService.selection();
              await Clipboard.setData(ClipboardData(text: csvContent));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Copiado al portapapeles.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copiar de nuevo'),
          ),
        ],
      ),
    );
  }

  static String _escapeCsv(String value) {
    return value.replaceAll('"', '""');
  }
}
