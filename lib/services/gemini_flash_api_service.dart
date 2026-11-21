import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'gemini_service.dart';

/// Servicio oficial de integración con Gemini Flash API para AirSight
class GeminiFlashApiService {
  // Clave activa validada en Google AI Studio
  static const String _apiKey =
      'TU_API_KEY_AQUI'; // Reemplaza con tu clave

  // Modelo oficial confirmado por la API
  static const String _modelName = 'gemini-3.8-flash';

  // Endpoint base para generateContent
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent';

  static String get apiKey => _apiKey;
  static String get modelName => _modelName;
  static String get baseUrl => _baseUrl;
  static GeminiService get instance => GeminiService.instance;

  /// Ejecuta una petición HTTP POST directa hacia la API REST de Gemini con trazas explícitas
  /// de diagnóstico y sin enmascarar errores HTTP.
  static Future<String> postGenerateContent({
    required Map<String, dynamic> payload,
    String? model,
    String? apiKeyOverride,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final effectiveModel = (model != null && model.trim().isNotEmpty)
        ? model.trim()
        : _modelName;
    final effectiveKey =
        (apiKeyOverride != null && apiKeyOverride.trim().isNotEmpty)
            ? apiKeyOverride.trim()
            : _apiKey;

    final Uri url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$effectiveModel:generateContent?key=$effectiveKey',
    );

    final String encodedPayload = jsonEncode(payload);
    debugPrint('>>> [AIRSIGHT REQUEST] URL: $url');
    debugPrint(
      '>>> [AIRSIGHT REQUEST] Payload Size: ${encodedPayload.length} bytes',
    );

    final http.Response response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: encodedPayload,
        )
        .timeout(
          timeout,
          onTimeout: () => throw TimeoutException(
            'La API tardó demasiado en responder (Timeout de ${timeout.inSeconds}s).',
          ),
        );

    debugPrint('>>> [AIRSIGHT RESPONSE] Status: ${response.statusCode}');
    debugPrint('>>> [AIRSIGHT RESPONSE] Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Fallo HTTP ${response.statusCode}: ${response.body}');
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Respuesta de Gemini sin candidates: ${response.body}');
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw Exception(
        'Respuesta de Gemini sin parts de texto: ${response.body}',
      );
    }

    final text = parts.first['text']?.toString() ?? '';
    // Limpieza de delimitadores markdown antes de devolver el texto crudo
    return text.replaceAll(RegExp(r'```json|```'), '').trim();
  }
}
