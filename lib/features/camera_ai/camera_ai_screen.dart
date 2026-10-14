import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../core/services/haptic_service.dart';
import '../../core/services/progress_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../services/gemini_service.dart';

/// Alias de compatibilidad hacia CameraAiScreen según especificación IEEE 830
typedef CameraScreen = CameraAiScreen;

/// Pantalla moderna y accesible de exploración visual con IA (Estilo Lovable / shadcn).
/// Utiliza Gemini para identificar objetos cotidianos básicos de nivel A1
/// cumpliendo rigurosamente con RF-03, RF-04, RF-05, RNF-01, RNF-02 y RNF-03.
class CameraAiScreen extends StatefulWidget {
  const CameraAiScreen({super.key});

  @override
  State<CameraAiScreen> createState() => _CameraAiScreenState();
}

class _CameraAiScreenState extends State<CameraAiScreen> {
  final TtsService _ttsService = TtsService();

  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isAnalyzing = false;

  Map<String, dynamic>? _detectedData;
  String? _detectionError;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _ttsService.stop();
    super.dispose();
  }

  /// Inicializa la cámara física si los controladores y el hardware están disponibles
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
      });
    } catch (_) {}
  }

  /// Comprobación rápida de conectividad a internet (< 1s) según RNF-02
  Future<bool> _hayConexionInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(milliseconds: 900));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Captura un fotograma de la cámara real y lo envía a Gemini 
  Future<void> _captureFromCamera() async {
    if (_isAnalyzing) return;

    // 1. Verificación previa de hardware de cámara
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await _initCamera();
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        const msg = 'La cámara no está disponible o no se han concedido permisos.';
        SemanticsService.announce(msg, TextDirection.ltr);
        await _ttsService.speakSpanish(msg);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(msg)),
          );
        }
        return;
      }
    }

    // 2. Validación Offline Previa (< 1s) (RNF-02)
    final bool conectado = await _hayConexionInternet();
    if (!conectado) {
      await HapticFeedback.heavyImpact();
      const msg = 'Se requiere conexión a internet para analizar la imagen';
      SemanticsService.announce(msg, TextDirection.ltr);
      await _ttsService.speakSpanish(msg);
      if (mounted) {
        setState(() {
          _detectedData = null;
          _detectionError = msg;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(msg)),
        );
      }
      return;
    }

    // 3. Retroalimentación Inmediata (< 400ms) (RNF-01 / Sec 3.2.3)
    await HapticFeedback.mediumImpact();
    SemanticsService.announce(
      'Capturando y analizando imagen, por favor espera...',
      TextDirection.ltr,
    );

    setState(() {
      _isAnalyzing = true;
      _detectedData = null;
      _detectionError = null;
    });

    // 4. Captura fotográfica e inferencia exclusivamente en memoria volátil (RNF-03)
    try {
      final xfile = await _cameraController!.takePicture();
      final bytes = await xfile.readAsBytes();

      // Eliminación inmediata del archivo temporal del almacenamiento persistente
      try {
        await File(xfile.path).delete();
      } catch (e) {
        debugPrint('[RNF-03] Archivo temporal limpiado: $e');
      }

      await _analyzeImageBytes(bytes);
    } catch (e) {
      debugPrint('Error al capturar imagen: $e');
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al capturar imagen: $e')),
      );
    }
  }

  /// Genera una imagen JPEG en memoria para probar objetos de muestra (Emulador)
  Uint8List _generateSampleJpg(String label) {
    final image = img.Image(width: 320, height: 240);
    img.fill(image, color: img.ColorRgb8(245, 247, 250));
    img.drawString(
      image,
      label,
      font: img.arial24,
      x: 35,
      y: 100,
      color: img.ColorRgb8(30, 41, 59),
    );
    return Uint8List.fromList(img.encodeJpg(image));
  }

  /// Analiza los bytes de la imagen con la instrucción estricta de Gemini
  Future<void> _analyzeImageBytes(Uint8List bytes) async {
    if (!_isAnalyzing) {
      setState(() {
        _isAnalyzing = true;
        _detectedData = null;
        _detectionError = null;
      });
      SemanticsService.announce(
        'Capturando y analizando imagen, por favor espera...',
        TextDirection.ltr,
      );
    }

    final result = await GeminiService.instance.identificarObjetoA1(bytes);
    if (!mounted) return;

    setState(() {
      _isAnalyzing = false;
    });

    if (result['exito'] == true) {
      setState(() {
        _detectedData = result;
        _detectionError = null;
      });

      await HapticFeedback.lightImpact();
      await ProgressService.registerCameraUse();
      await ProgressService.registerAudioPlay();

      final palabra = (result['palabraIngles'] as String? ?? '').trim();
      final traduccion = (result['traduccionEspanol'] as String? ?? '').trim();
      final frase = (result['fraseIngles'] as String? ?? '').trim();
      final fraseEs = (result['fraseEspanol'] as String? ?? '').trim();

      // Anuncio accesible a TalkBack
      final anuncio = 'Objeto identificado: $palabra, en español $traduccion.';
      SemanticsService.announce(anuncio, TextDirection.ltr);

      // Locución Bilingüe Secuencial (RF-04 / RF-05)
      await _ttsService.speakCameraRecognitionResult(
        wordEn: palabra,
        wordEs: traduccion,
        sentenceEn: frase,
        sentenceEs: fraseEs,
      );
    } else {
      await HapticFeedback.heavyImpact();

      final bool es503 = result['esError503'] == true;
      final bool esConexion = result['esErrorConexion'] == true;

      final String errorMsg;
      if (es503) {
        errorMsg =
            'Servicio de reconocimiento no disponible temporalmente. Intenta en un momento.';
      } else if (esConexion) {
        errorMsg = 'Se requiere conexión a internet para analizar la imagen';
      } else {
        final rawMsg = result['mensaje'] as String? ?? '';
        errorMsg = rawMsg.isNotEmpty
            ? rawMsg
            : 'Objeto no reconocido o no disponible en el glosario A1';
      }

      setState(() {
        _detectedData = null;
        _detectionError = errorMsg;
      });

      SemanticsService.announce(errorMsg, TextDirection.ltr);
      await _ttsService.speakSpanish(errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _detectedData;
    final error = _detectionError;

    final String? palabraIngles = data?['palabraIngles'];
    final String? traduccionEspanol = data?['traduccionEspanol'];
    final String? categoria = data?['categoria'];
    final String? fraseIngles = data?['fraseIngles'];
    final String? fraseEspanol = data?['fraseEspanol'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar con cámara'),
        actions: [
          // Menú discreto para desarrolladores / emulador sin cámara física
          PopupMenuButton<String>(
            tooltip: 'Muestras de prueba (Emulador)',
            icon: Icon(
              Icons.science_outlined,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            onSelected: (val) {
              if (_isAnalyzing) return;
              if (val == 'chair') _analyzeImageBytes(_generateSampleJpg('Chair'));
              if (val == 'laptop') _analyzeImageBytes(_generateSampleJpg('Laptop Computer'));
              if (val == 'book') _analyzeImageBytes(_generateSampleJpg('Book'));
              if (val == 'turbine') {
                _analyzeImageBytes(
                  _generateSampleJpg('Complex Industrial Steam Turbine Engine'),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'chair', child: Text('Probar Silla (A1)')),
              PopupMenuItem(value: 'laptop', child: Text('Probar Laptop (A1)')),
              PopupMenuItem(value: 'book', child: Text('Probar Libro (A1)')),
              PopupMenuItem(value: 'turbine', child: Text('Probar Rechazo (No A1)')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // VISOR MODERNO DE CÁMARA (Bordes redondeados de 24 dp según RF-03 / Estilo Lovable)
            Semantics(
              label: 'Visor de la cámara con marco de enfoque para identificar objetos.',
              child: Container(
                height: 340,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: const Color(0xFF0F172A),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    if (_isCameraReady && _cameraController != null)
                      Positioned.fill(
                        child: CameraPreview(_cameraController!),
                      )
                    else
                      Positioned.fill(
                        child: Center(
                          child: _isAnalyzing
                              ? const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: AppTheme.primary,
                                      strokeWidth: 3,
                                    ),
                                    SizedBox(height: 18),
                                    Text(
                                      'Analizando con Gemini...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: AppTheme.primary,
                                        size: 48,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Escáner Visual A1',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 24),
                                      child: Text(
                                        'Apunta a un objeto cotidiano de estudio, casa o comida.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                    // Esquinas iluminadas futuristas (Scanner overlay)
                    const Positioned.fill(
                      child: _ScannerCornerOverlay(),
                    ),

                    // Overlay de análisis activo con LiveRegion accesible para TalkBack
                    if (_isAnalyzing)
                      Positioned.fill(
                        child: Semantics(
                          liveRegion: true,
                          label: 'Capturando y analizando imagen, por favor espera...',
                          child: Container(
                            color: const Color(0xFF0B0F19).withValues(alpha: 0.80),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CircularProgressIndicator(
                                      color: AppTheme.primary,
                                      strokeWidth: 3.5,
                                    ),
                                  ),
                                  SizedBox(height: 18),
                                  Text(
                                    'Identificando objeto con Gemini...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // BOTÓN PRINCIPAL DE CAPTURA FLOTANTE / ERGONÓMICO (≥ 56 dp / WCAG 2.2 AA)
            Semantics(
              button: true,
              label: 'Capturar foto para identificar objeto en inglés',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1), // Vibrant Indigo
                      Color(0xFF4F46E5), // Deep Indigo
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _isAnalyzing ? null : _captureFromCamera,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isAnalyzing)
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(
                              Icons.camera_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          const SizedBox(width: 12),
                          Text(
                            _isAnalyzing ? 'Analizando...' : 'Capturar y Analizar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // TARJETA DE RESULTADO FLOTANTE ACCESIBLE (Estilo Lovable / shadcn)
            if (data != null && palabraIngles != null)
              Semantics(
                label:
                    'Objeto identificado: $palabraIngles, en español $traduccionEspanol. Categoría: $categoria. Frase: $fraseIngles. Traducción: $fraseEspanol.',
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge superior y botón cerrar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.secondary.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.secondary,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Objeto A1 Detectado',
                                  style: TextStyle(
                                    color: Color(0xFF6EE7B7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            tooltip: 'Cerrar resultado',
                            onPressed: () {
                              HapticService.selection();
                              setState(() => _detectedData = null);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Término en inglés destacado en grande + botón de audio
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  palabraIngles,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '→ ${traduccionEspanol ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Botón destacado con altavoz para repetir la pronunciación
                          Semantics(
                            button: true,
                            label: 'Pronunciar $palabraIngles en inglés',
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.40),
                                ),
                              ),
                              child: IconButton(
                                iconSize: 28,
                                icon: const Icon(
                                  Icons.volume_up_rounded,
                                  color: AppTheme.primary,
                                ),
                                onPressed: () {
                                  HapticService.selection();
                                  _ttsService.speakEnglish(palabraIngles);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (categoria != null && categoria.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Categoría: $categoria',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],

                      if (fraseIngles != null && fraseIngles.isNotEmpty) ...[
                        const Divider(height: 28),
                        const Text(
                          'Ejemplo en contexto:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '"$fraseIngles"',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                          ),
                        ),
                        if (fraseEspanol != null && fraseEspanol.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            fraseEspanol,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                HapticService.selection();
                                _ttsService.speakCameraRecognitionResult(
                                  wordEn: palabraIngles,
                                  wordEs: traduccionEspanol ?? '',
                                  sentenceEn: fraseIngles,
                                  sentenceEs: fraseEspanol ?? '',
                                );
                              },
                              icon: const Icon(Icons.replay_rounded, size: 18),
                              label: const Text('Repetir locución completa'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                HapticService.selection();
                                _ttsService.speakBilingual(
                                  textEn: fraseIngles,
                                  textEs: fraseEspanol ?? '',
                                );
                              },
                              icon: const Icon(Icons.record_voice_over_rounded, size: 18),
                              label: const Text('Escuchar solo ejemplo'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Tarjeta de aviso de rechazo o error controlado
            if (error != null)
              Semantics(
                label: 'Aviso de detección. $error',
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.warning,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Aviso de Inferencia',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              error,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Overlay de esquinas iluminadas futuristas estilo escáner Lovable
class _ScannerCornerOverlay extends StatelessWidget {
  const _ScannerCornerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            // Top-left
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.primary, width: 3.5),
                    left: BorderSide(color: AppTheme.primary, width: 3.5),
                  ),
                ),
              ),
            ),
            // Top-right
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.primary, width: 3.5),
                    right: BorderSide(color: AppTheme.primary, width: 3.5),
                  ),
                ),
              ),
            ),
            // Bottom-left
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.primary, width: 3.5),
                    left: BorderSide(color: AppTheme.primary, width: 3.5),
                  ),
                ),
              ),
            ),
            // Bottom-right
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.primary, width: 3.5),
                    right: BorderSide(color: AppTheme.primary, width: 3.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
