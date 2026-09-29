class GlossaryWord {
  final String id;
  final String wordEn;
  final String wordEs;
  final String category;
  final String exampleEn;
  final String exampleEs;
  final List<String> aliases;

  /// Alias de compatibilidad hacia [exampleEn].
  String get example => exampleEn;

  const GlossaryWord({
    required this.id,
    required this.wordEn,
    required this.wordEs,
    required this.category,
    required this.exampleEn,
    required this.exampleEs,
    this.aliases = const [],
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

  /// Evalúa si la palabra o sus variantes léxicas coinciden con la consulta de búsqueda,
  /// comparando contra wordEn, wordEs, category y la lista de aliases (sinónimos/regionalismos).
  bool matches(String query) {
    final cleanQuery = normalize(query);
    if (cleanQuery.isEmpty) return true;

    if (normalize(wordEn).contains(cleanQuery)) return true;
    if (normalize(wordEs).contains(cleanQuery)) return true;
    if (normalize(category).contains(cleanQuery)) return true;
    for (final alias in aliases) {
      if (normalize(alias).contains(cleanQuery)) return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wordEn': wordEn,
      'wordEs': wordEs,
      'category': category,
      'exampleEn': exampleEn,
      'example': exampleEn,
      'exampleEs': exampleEs,
      'aliases': aliases,
    };
  }

  factory GlossaryWord.fromJson(Map<String, dynamic> json) {
    final enExample = json['exampleEn']?.toString() ?? json['example']?.toString() ?? '';
    return GlossaryWord(
      id: json['id']?.toString() ?? '',
      wordEn: json['wordEn']?.toString() ?? '',
      wordEs: json['wordEs']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      exampleEn: enExample,
      exampleEs: json['exampleEs']?.toString() ?? '',
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}