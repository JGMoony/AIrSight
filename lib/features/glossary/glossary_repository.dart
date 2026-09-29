import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'glossary_data.dart';
import 'glossary_word.dart';

class GlossaryRepository {
  static const String _storageKey = 'custom_glossary_words_v3';

  /// Obtiene la lista actual de palabras (80 a 150 palabras).
  /// Si existen modificaciones guardadas por el Administrador, las carga;
  /// de lo contrario, retorna el catálogo base de 102 palabras.
  static Future<List<GlossaryWord>> getWords() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_storageKey);

    if (rawJson == null) {
      return List<GlossaryWord>.from(glossaryWords);
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawJson);
      final list = decoded.map((item) {
        final w = GlossaryWord.fromJson(item as Map<String, dynamic>);
        final defaultWord = glossaryWords.firstWhere(
          (def) => def.id == w.id || def.wordEn.toLowerCase() == w.wordEn.toLowerCase(),
          orElse: () => w,
        );
        final mergedAliases = {...w.aliases, ...defaultWord.aliases}.toList();
        return GlossaryWord(
          id: w.id,
          wordEn: w.wordEn,
          wordEs: w.wordEs,
          category: w.category,
          exampleEn: w.exampleEn.isNotEmpty ? w.exampleEn : defaultWord.exampleEn,
          exampleEs: w.exampleEs.isNotEmpty ? w.exampleEs : defaultWord.exampleEs,
          aliases: mergedAliases,
        );
      }).toList();

      if (list.isEmpty) {
        return List<GlossaryWord>.from(glossaryWords);
      }
      return list;
    } catch (_) {
      return List<GlossaryWord>.from(glossaryWords);
    }
  }

  /// Guarda una nueva lista de palabras (actualización inmediata)
  static Future<void> saveWords(List<GlossaryWord> words) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(words.map((w) => w.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  /// Agrega una palabra al catálogo (HU-09)
  static Future<void> addWord(GlossaryWord word) async {
    final current = await getWords();
    current.removeWhere((w) => w.id == word.id || w.wordEn.toLowerCase() == word.wordEn.toLowerCase());
    current.add(word);
    await saveWords(current);
  }

  /// Modifica una entrada de vocabulario existente (HU-09)
  static Future<void> updateWord(GlossaryWord word) async {
    final current = await getWords();
    final index = current.indexWhere((w) => w.id == word.id);
    if (index != -1) {
      current[index] = word;
    } else {
      current.add(word);
    }
    await saveWords(current);
  }

  /// Elimina una entrada del catálogo (HU-09)
  static Future<void> deleteWord(String id) async {
    final current = await getWords();
    current.removeWhere((w) => w.id == id);
    await saveWords(current);
  }

  /// Importa un archivo de configuración en formato JSON (HU-09)
  static Future<bool> importFromJson(String jsonString) async {
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      final imported = decoded
          .map((item) => GlossaryWord.fromJson(item as Map<String, dynamic>))
          .toList();

      if (imported.isNotEmpty) {
        await saveWords(imported);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Exporta el catálogo actual a formato JSON para consola/backup
  static Future<String> exportToJson() async {
    final words = await getWords();
    return jsonEncode(words.map((w) => w.toJson()).toList());
  }

  /// Restaura el catálogo original base de 102 palabras
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
