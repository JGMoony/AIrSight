import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/services/haptic_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/voice_search_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local_user_storage.dart';
import 'glossary_data.dart';
import 'glossary_detail_screen.dart';
import 'glossary_repository.dart';
import 'glossary_word.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final TtsService _ttsService = TtsService();
  final VoiceSearchService _voiceService = VoiceSearchService();
  final TextEditingController _searchController = TextEditingController();

  List<GlossaryWord> _words = glossaryWords;
  bool _isAdmin = false;
  bool _isListening = false;
  String searchText = '';
  String selectedCategory = 'Todas';

  @override
  void initState() {
    super.initState();
    _loadWords();
    _checkAdminRole();
  }

  Future<void> _loadWords() async {
    final words = await GlossaryRepository.getWords();
    if (!mounted) return;
    setState(() {
      _words = words;
    });
  }

  Future<void> _checkAdminRole() async {
    final user = await LocalUserStorage.getUser();
    if (!mounted) return;
    setState(() {
      _isAdmin = user?.role == 'admin';
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    _voiceService.stop();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceSearch() async {
    await HapticService.selection();
    if (_isListening) {
      await _voiceService.stop();
      setState(() {
        _isListening = false;
      });
      return;
    }

    final started = await _voiceService.startListening(
      onResult: (text, isFinal) {
        setState(() {
          searchText = text;
          _searchController.text = text;
        });

        if (isFinal) {
          setState(() {
            _isListening = false;
          });
          _evaluateSearchResults(text);
        }
      },
      onError: (err) {
        setState(() {
          _isListening = false;
        });
        SemanticsService.announce(
          'No se detectó audio del micrófono.',
          TextDirection.ltr,
        );
      },
    );

    if (started) {
      setState(() {
        _isListening = true;
      });
      SemanticsService.announce(
        'Micrófono activado. Di una palabra en inglés o español.',
        TextDirection.ltr,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo acceder al micrófono.')),
      );
    }
  }

  Future<void> _evaluateSearchResults(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    final results = _filteredWords;

    if (results.isEmpty) {
      // Criterio de aceptación IEEE 830 HU-06:
      const notFoundMessage =
          'La palabra no se encuentra disponible en el glosario A1.';
      SemanticsService.announce(notFoundMessage, TextDirection.ltr);
      await _ttsService.speakSpanish(notFoundMessage);
    } else {
      final foundMessage =
          'Se encontraron ${results.length} coincidencias para "$cleanQuery".';
      SemanticsService.announce(foundMessage, TextDirection.ltr);
      await _ttsService.speakSpanish(foundMessage);
    }
  }

  List<String> get _categories {
    final categories = _words.map((word) => word.category).toSet().toList()
      ..sort();

    return ['Todas', ...categories];
  }

  int _countByCategory(String category) {
    if (category == 'Todas') {
      return _words.length;
    }

    return _words.where((word) => word.category == category).length;
  }

  /// Normaliza una cadena de texto para búsquedas insensibles a mayúsculas y acentos diacríticos
  /// (ej. "platano" coincide con "plátano", "boligrafo" con "bolígrafo").
  String _normalizeText(String input) {
    const withAccents = 'áàäâãéèëêíìïîóòöôõúùüûÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛ';
    const withoutAccents = 'aaaaaeeeeiiiiooooouuuuaaaaaeeeeiiiiooooouuuu';
    var result = input.toLowerCase().trim();
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  List<GlossaryWord> get _filteredWords {
    final query = _normalizeText(searchText);

    final words = _words.where((word) {
      final matchesSearch = query.isEmpty ||
          _normalizeText(word.wordEn).contains(query) ||
          _normalizeText(word.wordEs).contains(query) ||
          _normalizeText(word.category).contains(query) ||
          word.aliases.any(
            (alias) => _normalizeText(alias).contains(query),
          );

      final matchesCategory =
          selectedCategory == 'Todas' || word.category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    words.sort(
      (a, b) => a.wordEn.toLowerCase().compareTo(b.wordEn.toLowerCase()),
    );

    return words;
  }

  Future<void> _playWord(GlossaryWord word) async {
    await HapticService.selection();
    await _ttsService.speakEnglish(word.wordEn);
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'classroom':
        return Icons.school_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'colors':
        return Icons.palette_rounded;
      case 'numbers':
        return Icons.numbers_rounded;
      case 'body':
        return Icons.accessibility_new_rounded;
      case 'objects':
        return Icons.category_rounded;
      case 'animals':
        return Icons.pets_rounded;
      case 'clothes':
        return Icons.checkroom_rounded;
      case 'people':
        return Icons.people_alt_rounded;
      case 'places':
        return Icons.location_city_rounded;
      case 'nature':
        return Icons.park_rounded;
      case 'todas':
        return Icons.apps_rounded;
      default:
        return Icons.label_rounded;
    }
  }

  Color _colorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'classroom':
        return const Color(0xFF2ECC71);
      case 'home':
        return const Color(0xFFFFA726);
      case 'food':
        return const Color(0xFFE91E63);
      case 'colors':
        return const Color(0xFF8E67F0);
      case 'numbers':
        return const Color(0xFF42A5F5);
      case 'body':
        return const Color(0xFFFF7043);
      case 'objects':
        return const Color(0xFF26A69A);
      case 'animals':
        return const Color(0xFF8D6E63);
      case 'clothes':
        return const Color(0xFF607D8B);
      case 'people':
        return const Color(0xFF5C6BC0);
      case 'places':
        return const Color(0xFF009688);
      case 'nature':
        return const Color(0xFF66BB6A);
      case 'todas':
        return AppTheme.primary;
      default:
        return AppTheme.primary;
    }
  }

  void _openDetail(GlossaryWord word) {
    HapticService.selection();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GlossaryDetailScreen(word: word),
      ),
    );
  }

  Future<void> _showAdminMenu() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Gestión de Vocabulario (Admin)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                  title: const Text('Agregar nueva palabra A1'),
                  subtitle: const Text('Crear un nuevo término con traducción y ejemplo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddWordDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restart_alt_rounded, color: Colors.orange),
                  title: const Text('Restaurar catálogo base'),
                  subtitle: const Text('Reiniciar a las 102 palabras predeterminadas'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await GlossaryRepository.resetToDefault();
                    await _loadWords();
                    SemanticsService.announce('Catálogo restaurado a valores base.', TextDirection.ltr);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Catálogo restaurado a las 102 palabras originales.')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddWordDialog() async {
    final wordEnController = TextEditingController();
    final wordEsController = TextEditingController();
    final categoryController = TextEditingController(text: 'Classroom');
    final exampleController = TextEditingController();
    final exampleEsController = TextEditingController();
    final aliasesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Agregar palabra A1'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: wordEnController,
                    decoration: const InputDecoration(labelText: 'Palabra en inglés (ej. desk)'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: wordEsController,
                    decoration: const InputDecoration(labelText: 'Traducción en español (ej. escritorio)'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Categoría (ej. Classroom, Home, Food)'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: exampleController,
                    decoration: const InputDecoration(labelText: 'Ejemplo en inglés (ej. The desk is clean.)'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: exampleEsController,
                    decoration: const InputDecoration(labelText: 'Ejemplo en español (ej. El escritorio está limpio.)'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: aliasesController,
                    decoration: const InputDecoration(
                      labelText: 'Aliases IA separados por coma',
                      hintText: 'desk, table, furniture',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final aliases = aliasesController.text
                    .split(',')
                    .map((e) => e.trim().toLowerCase())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final newWord = GlossaryWord(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  wordEn: wordEnController.text.trim().toLowerCase(),
                  wordEs: wordEsController.text.trim().toLowerCase(),
                  category: categoryController.text.trim(),
                  exampleEn: exampleController.text.trim(),
                  exampleEs: exampleEsController.text.trim(),
                  aliases: aliases.isEmpty ? [wordEnController.text.trim().toLowerCase()] : aliases,
                );

                Navigator.pop(ctx);
                await GlossaryRepository.addWord(newWord);
                await _loadWords();

                SemanticsService.announce('Palabra agregada exitosamente.', TextDirection.ltr);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Palabra "${newWord.wordEn}" guardada.')),
                );
              },
              child: const Text('Guardar palabra'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredWords = _filteredWords;
    final totalCategories = _words.map((word) => word.category).toSet().length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Glosario A1'),
        actions: [
          if (_isAdmin)
            Semantics(
              label: 'Administrar vocabulario A1',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Gestionar vocabulario (Admin)',
                onPressed: _showAdminMenu,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Text(
              'Explora y aprende vocabulario básico',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),

            const SizedBox(height: 18),

            _SearchBox(
              controller: _searchController,
              isListening: _isListening,
              onMicPressed: _toggleVoiceSearch,
              onSubmitted: _evaluateSearchResults,
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              onClear: () {
                HapticService.selection();
                setState(() {
                  searchText = '';
                  _searchController.clear();
                });
                SemanticsService.announce(
                  'Búsqueda borrada. Mostrando todas las categorías.',
                  TextDirection.ltr,
                );
              },
            ),

            if (searchText.trim().isEmpty) ...[
              const SizedBox(height: 20),

              _SummaryCard(
                totalWords: _words.length,
                totalCategories: totalCategories,
              ),

              const SizedBox(height: 20),

              const Text(
                'Categorías',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = selectedCategory == category;
                  final color = _colorForCategory(category);

                  return _CategoryCard(
                    category: category,
                    count: _countByCategory(category),
                    icon: _iconForCategory(category),
                    color: color,
                    isSelected: isSelected,
                    onTap: () {
                      HapticService.selection();
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  );
                },
              ),
            ],

            const SizedBox(height: 22),

            Semantics(
              header: true,
              liveRegion: true,
              label: searchText.trim().isNotEmpty
                  ? 'Resultados de búsqueda: ${filteredWords.length} palabras encontradas'
                  : (selectedCategory == 'Todas'
                      ? 'Todas las palabras: ${filteredWords.length} disponibles'
                      : 'Palabras de $selectedCategory: ${filteredWords.length} disponibles'),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      searchText.trim().isNotEmpty
                          ? 'Resultados para "${searchText.trim()}"'
                          : (selectedCategory == 'Todas'
                              ? 'Todas las palabras'
                              : 'Palabras de $selectedCategory'),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${filteredWords.length}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (filteredWords.isEmpty)
              const _EmptyState()
            else
              ...filteredWords.map(
                (word) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _WordCard(
                    word: word,
                    categoryColor: _colorForCategory(word.category),
                    onTap: () => _openDetail(word),
                    onPlay: () => _playWord(word),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isListening;
  final VoidCallback onMicPressed;
  final ValueChanged<String> onSubmitted;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.isListening,
    required this.onMicPressed,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'Buscar palabra en inglés, español o categoría',
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: isListening ? 'Escuchando tu voz...' : 'Buscar palabra...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.text.isNotEmpty)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Borrar búsqueda',
                ),
              Semantics(
                label: isListening
                    ? 'Detener escucha de micrófono'
                    : 'Buscar palabra dictando por voz al micrófono',
                button: true,
                child: IconButton(
                  onPressed: onMicPressed,
                  icon: Icon(
                    isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: isListening ? Colors.red : AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalWords;
  final int totalCategories;

  const _SummaryCard({
    required this.totalWords,
    required this.totalCategories,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$totalWords palabras y $totalCategories categorías disponibles',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppTheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '$totalWords palabras · $totalCategories categorías',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final int count;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.count,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Categoría $category, $count palabras',
      button: true,
      selected: isSelected,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 27,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count palabras',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final GlossaryWord word;
  final Color categoryColor;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const _WordCard({
    required this.word,
    required this.categoryColor,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${word.wordEn}, traducción ${word.wordEs}, categoría ${word.category}. Ejemplo: ${word.exampleEn}. Traducción del ejemplo: ${word.exampleEs}. Toca dos veces para ver detalle.',
      button: true,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          word.category,
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        word.wordEn,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        word.wordEs,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"${word.exampleEn}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (word.exampleEs.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          word.exampleEs,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  label: 'Escuchar palabra ${word.wordEn}',
                  button: true,
                  child: IconButton.filledTonal(
                    onPressed: onPlay,
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No se encontraron palabras.',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}