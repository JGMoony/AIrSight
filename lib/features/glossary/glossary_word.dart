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
}