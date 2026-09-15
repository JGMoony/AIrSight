class GlossaryWord {
  final String id;
  final String wordEn;
  final String wordEs;
  final String category;
  final String example;
  final String exampleEs;
  final List<String> aliases;

  const GlossaryWord({
    required this.id,
    required this.wordEn,
    required this.wordEs,
    required this.category,
    required this.example,
    required this.exampleEs,
    this.aliases = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wordEn': wordEn,
      'wordEs': wordEs,
      'category': category,
      'example': example,
      'exampleEs': exampleEs,
      'aliases': aliases,
    };
  }

  factory GlossaryWord.fromJson(Map<String, dynamic> json) {
    return GlossaryWord(
      id: json['id']?.toString() ?? '',
      wordEn: json['wordEn']?.toString() ?? '',
      wordEs: json['wordEs']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      example: json['example']?.toString() ?? '',
      exampleEs: json['exampleEs']?.toString() ?? '',
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}