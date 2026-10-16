import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../services/haptic_service.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../services/gemini_service.dart';

/// Alias de compatibilidad hacia CameraAiScreen
typedef CameraScreen = CameraAiScreen;

/// Utiliza Gemini para identificar objetos cotidianos básicos de nivel A1
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

  /// Emite un anuncio semántico accesible para lectores de pantalla TalkBack (WCAG 2.2 AA).
  void _announce(String message) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Captura un fotograma de la cámara real y lo envía a Gemini 
  Future<void> _captureFromCamera() async {
    if (_isAnalyzing) return;

    // 1. Verificación previa de hardware de cámara
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await _initCamera();
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        const msg = 'La cámara no está disponible o no se han concedido permisos.';
        _announce(msg);
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
      await HapticService.error();
      const msg = 'Se requiere conexión a internet para utilizar este servicio';
      _announce(msg);
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
    await HapticService.buttonPress();
    _announce('Capturando y analizando imagen, por favor espera...');

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

  /// Analiza los bytes de la imagen con la instrucción estricta de Gemini
  Future<void> _analyzeImageBytes(Uint8List bytes) async {
    if (!_isAnalyzing) {
      setState(() {
        _isAnalyzing = true;
        _detectedData = null;
        _detectionError = null;
      });
      _announce('Capturando y analizando imagen, por favor espera...');
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

      await HapticService.success();
      await ProgressService.registerCameraUse();
      await ProgressService.registerAudioPlay();

      final palabra = (result['palabraIngles'] as String? ?? '').trim();
      final traduccion = (result['traduccionEspanol'] as String? ?? '').trim();
      final frase = (result['fraseIngles'] as String? ?? '').trim();
      final fraseEs = (result['fraseEspanol'] as String? ?? '').trim();

      // Anuncio accesible a TalkBack
      final anuncio = 'Objeto identificado: $palabra, en español $traduccion.';
      _announce(anuncio);

      // Locución Bilingüe Secuencial (RF-04 / RF-05)
      await _ttsService.speakCameraRecognitionResult(
        wordEn: palabra,
        wordEs: traduccion,
        sentenceEn: frase,
        sentenceEs: fraseEs,
      );
    } else {
      await HapticService.error();

      final bool es503 = result['esError503'] == true;
      final bool esConexion = result['esErrorConexion'] == true;

      final String errorMsg;
      if (es503) {
        errorMsg =
            'Servicio de reconocimiento no disponible temporalmente. Intenta en un momento.';
      } else if (esConexion) {
        errorMsg = 'Se requiere conexión a internet para utilizar este servicio';
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

      _announce(errorMsg);
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
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // VISOR DE CÁMARA (Ocupa 90-100% de la pantalla, bordes redondeados de 24 dp según RF-03)
            Positioned.fill(
              bottom: 92,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Semantics(
                  label:
                      'Visor de la cámara con marco de enfoque para identificar objetos.',
                  child: Container(
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
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.12),
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
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 24),
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
                              label:
                                  'Capturando y analizando imagen, por favor espera...',
                              child: Container(
                                color: const Color(0xFF0B0F19)
                                    .withValues(alpha: 0.80),
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
              ),
            ),

            // BOTÓN PRINCIPAL DE CAPTURA FLOTANTE (≥ 56 dp / WCAG 2.2 AA)
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: Semantics(
                button: true,
                label: 'Capturar y reconocer objeto',
                hint:
                    'Toca dos veces para tomar la foto y analizar el objeto con Inteligencia Artificial',
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
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
                              _isAnalyzing
                                  ? 'Analizando...'
                                  : 'Capturar y Analizar',
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
            ),

            // TARJETA DE RESULTADO FLOTANTE CENTRADA (Éxito)
            if (data != null && palabraIngles != null)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Semantics(
                        label:
                            'Objeto identificado: $palabraIngles, en español $traduccionEspanol. Categoría: $categoria.',
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
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge superior y botón cerrar
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondary
                                          .withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.secondary
                                            .withValues(alpha: 0.35),
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
                                            color: Color(0xFF059669),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        size: 22),
                                    tooltip: 'Cerrar resultado',
                                    onPressed: () {
                                      HapticService.selection();
                                      setState(() => _detectedData = null);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Término en inglés en grande + botón de audio
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          palabraIngles,
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.textPrimary,
                                            letterSpacing: -0.6,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '/$palabraIngles/',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primary,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '→ ${traduccionEspanol ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF059669),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Botón destacado con altavoz (≥ 48x48 dp)
                                  Semantics(
                                    button: true,
                                    label: 'Pronunciar $palabraIngles en inglés',
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.primary
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: IconButton(
                                        iconSize: 26,
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(
                                          Icons.volume_up_rounded,
                                          color: AppTheme.primary,
                                        ),
                                        onPressed: () {
                                          HapticService.selection();
                                          _ttsService
                                              .speakEnglish(palabraIngles);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (categoria != null &&
                                  categoria.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.08),
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

                              if (fraseIngles != null &&
                                  fraseIngles.isNotEmpty) ...[
                                const Divider(height: 24),
                                const Text(
                                  'Ejemplo en contexto:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '"$fraseIngles"',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                if (fraseEspanol != null &&
                                    fraseEspanol.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    fraseEspanol,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        HapticService.selection();
                                        _ttsService
                                            .speakCameraRecognitionResult(
                                          wordEn: palabraIngles,
                                          wordEs: traduccionEspanol ?? '',
                                          sentenceEn: fraseIngles,
                                          sentenceEs: fraseEspanol ?? '',
                                        );
                                      },
                                      icon: const Icon(Icons.replay_rounded,
                                          size: 18),
                                      label: const Text(
                                          'Repetir locución completa'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // TARJETA DE AVISO O ERROR FLOTANTE CENTRADA
            if (error != null)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  child: Center(
                    child: Semantics(
                      label: 'Aviso de detección. $error',
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.warning.withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.warning.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warning
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.info_outline_rounded,
                                        color: AppTheme.warning,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Aviso de Detección',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      size: 22),
                                  tooltip: 'Cerrar aviso',
                                  onPressed: () {
                                    HapticService.selection();
                                    setState(() => _detectionError = null);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              error,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
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
