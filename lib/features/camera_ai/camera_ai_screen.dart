import 'package:flutter/material.dart';
import '../../core/services/progress_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../glossary/glossary_data.dart';
import '../glossary/glossary_word.dart';

class CameraAiScreen extends StatefulWidget {
  const CameraAiScreen({super.key});

  @override
  State<CameraAiScreen> createState() => _CameraAiScreenState();
}

class _CameraAiScreenState extends State<CameraAiScreen> {
  final TtsService _ttsService = TtsService();
  GlossaryWord? _detectedWord;
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _simulateDetection() async {
    setState(() {
      _isAnalyzing = true;
      _detectedWord = null;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    final result = glossaryWords.firstWhere((word) => word.wordEn == 'chair');
    await ProgressService.registerCameraUse();
    await ProgressService.registerWordViewed(result.id);
    await ProgressService.registerAudioPlay();

    setState(() {
      _isAnalyzing = false;
      _detectedWord = result;
    });

    await _ttsService.speakSpanish('Objeto detectado. ${result.wordEn}, significa ${result.wordEs}.');
  }

  @override
  Widget build(BuildContext context) {
    final word = _detectedWord;

    return Scaffold(
      appBar: AppBar(title: const Text('Explorar con cámara')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              height: 310,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF334155)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Center(
                      child: _isAnalyzing
                          ? const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 18),
                                Text('Analizando imagen...', style: TextStyle(color: Colors.white, fontSize: 18)),
                              ],
                            )
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_rounded, color: Colors.white, size: 74),
                                SizedBox(height: 14),
                                Text('Vista previa de cámara', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                                SizedBox(height: 8),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 30),
                                  child: Text(
                                    'En la siguiente fase se conectará la cámara real y la API de visión artificial.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white70, fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    top: 18,
                    right: 18,
                    bottom: 18,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _simulateDetection,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Simular detección accesible'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _ttsService.speakSpanish('Módulo de cámara. Toma una foto para detectar un objeto y escuchar una palabra en inglés nivel A uno.'),
              icon: const Icon(Icons.info_outline_rounded),
              label: const Text('Escuchar instrucciones'),
            ),
            const SizedBox(height: 18),
            if (word != null)
              Semantics(
                label: 'Resultado de inteligencia artificial. ${word.wordEn}, ${word.wordEs}, categoría ${word.category}. Ejemplo ${word.example}',
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Resultado detectado', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Text(word.wordEn, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                        Text(word.wordEs, style: const TextStyle(fontSize: 22, color: AppTheme.textSecondary)),
                        const SizedBox(height: 10),
                        Text('Categoría: ${word.category}'),
                        Text('Ejemplo: ${word.example}'),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => _ttsService.speakEnglish(word.wordEn),
                          icon: const Icon(Icons.volume_up_rounded),
                          label: const Text('Escuchar palabra'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Nota técnica: esta pantalla ya deja preparado el flujo visual y accesible. El siguiente paso será reemplazar la simulación por cámara real, procesamiento de imagen y mapeo de etiquetas IA contra el glosario A1.',
                  style: TextStyle(height: 1.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
