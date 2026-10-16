import 'package:cloud_firestore/cloud_firestore.dart';

class GlossaryWord {
  final String id;
  final String wordEn;
  final String wordEs;
  final String category;
  final String exampleEn;
  final String exampleEs;
  final String _phonetic;
  final List<String> aliases;

  /// Etiquetas normalizadas para emparejamiento con el motor de visión artificial / IA.
  final List<String> etiquetasIA;

  /// Retorna la transcripción fonética legible (ej: /'æpl/, /kæt/, /bʊk/).
  String get phonetic =>
      _phonetic.isNotEmpty ? _phonetic : (a1Phonetics[wordEn.toLowerCase().trim()] ?? '/$wordEn/');

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
    String phonetic = '',
    this.aliases = const [],
    this.etiquetasIA = const [],
  }) : _phonetic = phonetic;

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

  /// Serialización estándar canónica para Cloud Firestore (colección 'glosario_a1') y almacenamiento local.
  /// Guarda ESTRICTAMENTE un conjunto único de claves canónicas sin duplicados en inglés ni español.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wordEn': wordEn,
      'wordEs': wordEs,
      'phonetic': phonetic,
      'exampleEn': exampleEn,
      'exampleEs': exampleEs,
      'category': category,
      if (aliases.isNotEmpty) 'aliases': aliases,
      if (etiquetas.isNotEmpty) 'etiquetasIA': etiquetas,
    };
  }

  /// Alias canónico de toMap para Cloud Firestore.
  Map<String, dynamic> toFirestore() => toMap();

  /// Alias de compatibilidad hacia toMap para SharedPreferences y JSON local.
  Map<String, dynamic> toJson() => toMap();

  /// Construye un GlossaryWord a partir de un DocumentSnapshot de Cloud Firestore.
  factory GlossaryWord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return GlossaryWord.fromMap(data, id: doc.id);
  }

  /// Construye un GlossaryWord desde un Map con parsing robusto, seguro de tipos y fallbacks compatibles.
  factory GlossaryWord.fromMap(Map<String, dynamic> map, {String id = ''}) {
    final enWord = (map['wordEn'] ?? map['palabraEn'] ?? '').toString();
    final esWord = (map['wordEs'] ?? map['traduccion'] ?? '').toString();
    final phoneticVal = (map['phonetic'] ?? map['fonetica'] ?? '').toString();
    final catVal = (map['category'] ?? map['categoria'] ?? 'General').toString();
    final enExample =
        (map['exampleEn'] ?? map['fraseEn'] ?? map['example'] ?? '').toString();
    final esExample = (map['exampleEs'] ?? map['fraseEs'] ?? '').toString();
    final rawAliases = (map['aliases'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final rawTags = (map['etiquetasIA'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        rawAliases;

    final finalId = (map['id'] as String?)?.isNotEmpty == true
        ? (map['id'] as String)
        : id;

    return GlossaryWord(
      id: finalId,
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

/// Transcripciones fonéticas legibles IPA/simples para el catálogo léxico A1
const Map<String, String> a1Phonetics = {
  'bird': '/bɜːrd/',
  'cat': '/kæt/',
  'cow': '/kaʊ/',
  'dog': '/dɔːɡ/',
  'duck': '/dʌk/',
  'fish': '/fɪʃ/',
  'horse': '/hɔːrs/',
  'lion': "/'laɪ.ən/",
  'mouse': '/maʊs/',
  'pig': '/pɪɡ/',
  'rabbit': "/'ræb.ɪt/",
  'turtle': "/'tɜːr.tl/",
  'bag': '/bæɡ/',
  'board': '/bɔːrd/',
  'book': '/bʊk/',
  'chair': '/tʃer/',
  'classroom': "/'klæs.ruːm/",
  'desk': '/desk/',
  'eraser': "/ɪ'reɪ.sər/",
  'marker': "/'mɑːr.kər/",
  'notebook': "/'noʊt.bʊk/",
  'pen': '/pen/',
  'pencil': "/'pen.səl/",
  'ruler': "/'ruː.lər/",
  'table': "/'teɪ.bl/",
  'bed': '/bed/',
  'bottle': "/'bɑː.tl/",
  'cup': '/kʌp/',
  'door': '/dɔːr/',
  'fork': '/fɔːrk/',
  'glass': '/ɡlæs/',
  'house': '/haʊs/',
  'kitchen': "/'kɪtʃ.ɪn/",
  'knife': '/naɪf/',
  'lamp': '/læmp/',
  'plate': '/pleɪt/',
  'refrigerator': "/rɪ'frɪdʒ.ə.reɪ.tər/",
  'spoon': '/spuːn/',
  'window': "/'wɪn.doʊ/",
  'apple': "/'æpl/",
  'banana': "/bə'næn.ə/",
  'bread': '/bred/',
  'cheese': '/tʃiːz/',
  'chicken': "/'tʃɪk.ɪn/",
  'coffee': "/'kɔː.fi/",
  'egg': '/eɡ/',
  'meat': '/miːt/',
  'milk': '/mɪlk/',
  'orange': "/'ɔːr.ɪndʒ/",
  'rice': '/raɪs/',
  'water': "/'wɔː.tər/",
  'boots': '/buːts/',
  'cap': '/kæp/',
  'dress': '/dres/',
  'hat': '/hæt/',
  'jacket': "/'dʒæk.ɪt/",
  'pants': '/pænts/',
  'shirt': '/ʃɜːrt/',
  'shoes': '/ʃuːz/',
  'skirt': '/skɜːrt/',
  'socks': '/sɑːks/',
  't-shirt': "/'tiː.ʃɜːrt/",
  'arm': '/ɑːrm/',
  'ear': '/ɪr/',
  'eye': '/aɪ/',
  'foot': '/fʊt/',
  'hand': '/hænd/',
  'head': '/hed/',
  'leg': '/leɡ/',
  'mouth': '/maʊθ/',
  'nose': '/noʊz/',
  'black': '/blæk/',
  'blue': '/bluː/',
  'brown': '/braʊn/',
  'green': '/ɡriːn/',
  'red': '/red/',
  'white': '/waɪt/',
  'yellow': "/'jel.oʊ/",
  'one': '/wʌn/',
  'two': '/tuː/',
  'three': '/θriː/',
  'four': '/fɔːr/',
  'five': '/faɪv/',
  'six': '/sɪks/',
  'seven': "/'sev.n/",
  'eight': '/eɪt/',
  'nine': '/naɪn/',
  'ten': '/ten/',
  'baby': "/'beɪ.bi/",
  'boy': '/bɔɪ/',
  'brother': "/'brʌð.ər/",
  'child': '/tʃaɪld/',
  'doctor': "/'dɑːk.tər/",
  'father': "/'fɑː.ðər/",
  'girl': '/ɡɜːrl/',
  'man': '/mæn/',
  'mother': "/'mʌð.ər/",
  'sister': "/'sɪs.tər/",
  'teacher': "/'tiː.tʃər/",
  'woman': "/'wʊm.ən/",
  'city': "/'sɪt.i/",
  'flower': "/'flaʊ.ər/",
  'park': '/pɑːrk/',
  'school': '/skuːl/',
  'street': '/striːt/',
  'sun': '/sʌn/',
  'tree': '/triː/',
  'bicycle': "/'baɪ.sɪ.kl/",
  'bus': '/bʌs/',
  'car': '/kɑːr/',
  'computer': "/kəm'pjuː.tər/",
  'phone': '/foʊn/',
  'clock': '/klɑːk/',
};