import 'package:cloud_firestore/cloud_firestore.dart';

class GlossaryWord {
  final String id;
  final String wordEn;
  final String wordEs;
  final String category;
  final String exampleEn;
  final String exampleEs;
  final String phonetic;
  final List<String> aliases;

  /// Etiquetas normalizadas para emparejamiento con el motor de visión artificial / IA.
  final List<String> etiquetasIA;

  /// Alias de compatibilidad hacia [exampleEn].
  String get example => exampleEn;

  /// Retorna las etiquetas activas para IA (etiquetasIA si existen, o la lista de aliases como fallback).
  List<String> get etiquetas => etiquetasIA.isNotEmpty ? etiquetasIA : aliases;

  const GlossaryWord({
    required this.id,
    required this.wordEn,
    required this.wordEs,
    required this.category,
    required this.exampleEn,
    required this.exampleEs,
    this.phonetic = '',
    this.aliases = const [],
    this.etiquetasIA = const [],
  });

  /// Normaliza una cadena de texto para búsquedas insensibles a mayúsculas y diacríticos (tildes/acentos).
  static String normalize(String text) {
    const withAccents = 'áàäâãéèëêíìïîóòöôõúùüûÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛ';
    const withoutAccents = 'aaaaaeeeeiiiiooooouuuuaaaaaeeeeiiiiooooouuuu';
    var result = text.toLowerCase().trim();
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  /// Evalúa si la palabra, sus variantes léxicas o sus etiquetas de IA coinciden con la consulta.
  bool matches(String query) {
    final cleanQuery = normalize(query);
    if (cleanQuery.isEmpty) return true;

    if (normalize(wordEn).contains(cleanQuery)) return true;
    if (normalize(wordEs).contains(cleanQuery)) return true;
    if (normalize(category).contains(cleanQuery)) return true;
    for (final alias in aliases) {
      if (normalize(alias).contains(cleanQuery)) return true;
    }
    for (final tag in etiquetasIA) {
      if (normalize(tag).contains(cleanQuery)) return true;
    }
    return false;
  }

  /// Evalúa si una etiqueta detectada por el modelo de IA (COCO / YOLO) coincide con este término.
  bool matchesAiLabel(String label) {
    final cleanLabel = normalize(label);
    if (normalize(wordEn) == cleanLabel) return true;
    if (normalize(wordEs) == cleanLabel) return true;
    if (aliases.any((alias) => normalize(alias) == cleanLabel)) return true;
    return etiquetasIA.any((tag) => normalize(tag) == cleanLabel);
  }

  /// Serialización para Cloud Firestore (colección 'glosario_a1') y almacenamiento local.
  Map<String, dynamic> toFirestore() {
    final effectiveTags = etiquetasIA.isNotEmpty ? etiquetasIA : aliases;
    return {
      'id': id,
      'wordEn': wordEn,
      'palabraEn': wordEn,
      'wordEs': wordEs,
      'traduccion': wordEs,
      'phonetic': phonetic,
      'fonetica': phonetic,
      'category': category,
      'categoria': category,
      'exampleEn': exampleEn,
      'fraseEn': exampleEn,
      'example': exampleEn,
      'exampleEs': exampleEs,
      'fraseEs': exampleEs,
      'aliases': aliases,
      'etiquetasIA': effectiveTags,
    };
  }

  /// Alias de toFirestore para compatibilidad con estándares de mapas.
  Map<String, dynamic> toMap() => toFirestore();

  /// Alias de compatibilidad hacia toFirestore para SharedPreferences y JSON local.
  Map<String, dynamic> toJson() => toFirestore();

  /// Construye un GlossaryWord a partir de un DocumentSnapshot de Cloud Firestore.
  factory GlossaryWord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return GlossaryWord.fromMap(data, id: doc.id);
  }

  /// Construye un GlossaryWord desde un Map con parsing robusto y seguro de tipos.
  factory GlossaryWord.fromMap(Map<String, dynamic> map, {String id = ''}) {
    final enWord =
        map['wordEn']?.toString() ?? map['palabraEn']?.toString() ?? '';
    final esWord =
        map['wordEs']?.toString() ?? map['traduccion']?.toString() ?? '';
    final phoneticVal =
        map['phonetic']?.toString() ?? map['fonetica']?.toString() ?? '';
    final catVal =
        map['category']?.toString() ?? map['categoria']?.toString() ?? '';
    final enExample = map['exampleEn']?.toString() ??
        map['fraseEn']?.toString() ??
        map['example']?.toString() ??
        '';
    final esExample =
        map['exampleEs']?.toString() ?? map['fraseEs']?.toString() ?? '';
    final rawAliases = (map['aliases'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final rawTags = (map['etiquetasIA'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        rawAliases;

    return GlossaryWord(
      id: (map['id'] as String?)?.isNotEmpty == true
          ? (map['id'] as String)
          : id,
      wordEn: enWord,
      wordEs: esWord,
      category: catVal,
      exampleEn: enExample,
      exampleEs: esExample,
      phonetic: phoneticVal,
      aliases: rawAliases,
      etiquetasIA: rawTags,
    );
  }

  /// Constructor de fábrica para deserialización desde JSON / SharedPreferences.
  factory GlossaryWord.fromJson(Map<String, dynamic> json) =>
      GlossaryWord.fromMap(json);
}