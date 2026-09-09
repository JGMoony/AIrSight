import 'package:flutter/material.dart';

import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import 'glossary_data.dart';
import 'glossary_detail_screen.dart';
import 'glossary_word.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final TtsService _ttsService = TtsService();
  final TextEditingController _searchController = TextEditingController();

  String searchText = '';
  String selectedCategory = 'Todas';

  @override
  void dispose() {
    _ttsService.stop();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final categories = glossaryWords.map((word) => word.category).toSet().toList()
      ..sort();

    return ['Todas', ...categories];
  }

  int _countByCategory(String category) {
    if (category == 'Todas') {
      return glossaryWords.length;
    }

    return glossaryWords.where((word) => word.category == category).length;
  }

  List<GlossaryWord> get _filteredWords {
    final query = searchText.toLowerCase().trim();

    final words = glossaryWords.where((word) {
      final matchesSearch = query.isEmpty ||
          word.wordEn.toLowerCase().contains(query) ||
          word.wordEs.toLowerCase().contains(query) ||
          word.category.toLowerCase().contains(query) ||
          word.aliases.any(
            (alias) => alias.toLowerCase().contains(query),
          );

      final matchesCategory =
          selectedCategory == 'Todas' || word.category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    words.sort(
      (a, b) => b.wordEn.toLowerCase().compareTo(a.wordEn.toLowerCase()),
    );

    return words;
  }

  Future<void> _playWord(GlossaryWord word) async {
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GlossaryDetailScreen(word: word),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredWords = _filteredWords;
    final totalCategories = glossaryWords.map((word) => word.category).toSet().length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Glosario A1'),
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
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              onClear: () {
                setState(() {
                  searchText = '';
                  _searchController.clear();
                });
              },
            ),

            const SizedBox(height: 20),

            _SummaryCard(
              totalWords: glossaryWords.length,
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
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedCategory == 'Todas'
                        ? 'Todas las palabras'
                        : 'Palabras de $selectedCategory',
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

  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'Buscar palabra en inglés, español o categoría',
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar palabra...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
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
                  color: AppTheme.primary.withOpacity(0.10),
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
                color: Colors.black.withOpacity(0.04),
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
                  color: color.withOpacity(0.12),
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
          '${word.wordEn}, ${word.wordEs}, categoría ${word.category}. Toca dos veces para ver detalle.',
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
                          color: categoryColor.withOpacity(0.12),
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
                        '"${word.example}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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