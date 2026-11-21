import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../core/theme/app_theme.dart';
import '../../services/haptic_service.dart';
import '../glossary/glossary_repository.dart';
import '../glossary/glossary_word.dart';

/// Pantalla completa y accesible para Creación y Edición de palabras del glosario A1 (CRUD: Create & Update).
/// Reemplaza diálogos flotantes para garantizar navegación limpia y compatible con TalkBack (WCAG 2.2 AA).
class AdminWordFormScreen extends StatefulWidget {
  final GlossaryWord? wordToEdit;

  const AdminWordFormScreen({
    super.key,
    this.wordToEdit,
  });

  bool get isEditing => wordToEdit != null;

  @override
  State<AdminWordFormScreen> createState() => _AdminWordFormScreenState();
}

class _AdminWordFormScreenState extends State<AdminWordFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _wordEnController;
  late final TextEditingController _wordEsController;
  late final TextEditingController _phoneticController;
  late final TextEditingController _exampleEnController;
  late final TextEditingController _exampleEsController;
  late final TextEditingController _aliasesController;
  late final TextEditingController _newCategoryController;

  static const String _createNewCategoryValue = '+ Crear nueva categoría';

  String _selectedCategory = 'Classroom';
  bool _isCreatingNewCategory = false;
  bool _isSaving = false;
  List<String> _availableCategories = [];

  void _announce(String message) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, TextDirection.ltr);
  }

  @override
  void initState() {
    super.initState();
    final word = widget.wordToEdit;

    _wordEnController = TextEditingController(text: word?.wordEn ?? '');
    _wordEsController = TextEditingController(text: word?.wordEs ?? '');
    _phoneticController = TextEditingController(text: word != null ? word.phonetic : '');
    _exampleEnController = TextEditingController(text: word?.exampleEn ?? '');
    _exampleEsController = TextEditingController(text: word?.exampleEs ?? '');
    _aliasesController = TextEditingController(text: word?.aliases.join(', ') ?? '');
    _newCategoryController = TextEditingController();

    if (word != null && word.category.isNotEmpty) {
      _selectedCategory = word.category;
    }

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final words = await GlossaryRepository.getWords();
    final set = <String>{
      'Classroom',
      'Home',
      'Food',
      'Animals',
      'Clothes',
      'Body',
      'Colors',
      'Numbers',
      'People',
      'Places',
      'Transport',
      'Technology',
      ...words.map((w) => w.category).where((c) => c.isNotEmpty),
      if (widget.wordToEdit != null) widget.wordToEdit!.category,
    };

    final sorted = set.toList()..sort();

    if (!mounted) return;
    setState(() {
      _availableCategories = sorted;
      if (!_availableCategories.contains(_selectedCategory)) {
        if (_availableCategories.isNotEmpty) {
          _selectedCategory = _availableCategories.first;
        }
      }
    });
  }

  @override
  void dispose() {
    _wordEnController.dispose();
    _wordEsController.dispose();
    _phoneticController.dispose();
    _exampleEnController.dispose();
    _exampleEsController.dispose();
    _aliasesController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  /// Genera automáticamente la transcripción fonética IPA del término en inglés.
  void _generateAutomaticPhonetic() {
    HapticService.selection();
    final englishTerm = _wordEnController.text.trim().toLowerCase();

    if (englishTerm.isEmpty) {
      _announce('Ingresa primero la palabra en inglés para generar su fonética.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe la palabra en inglés primero.'),
        ),
      );
      return;
    }

    String suggestedIpa;
    if (a1Phonetics.containsKey(englishTerm)) {
      suggestedIpa = a1Phonetics[englishTerm]!;
    } else {
      suggestedIpa = '/$englishTerm/';
    }

    setState(() {
      _phoneticController.text = suggestedIpa;
    });

    _announce('Fonética generada: $suggestedIpa');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fonética sugerida: $suggestedIpa (puedes editarla libremente).'),
      ),
    );
  }

  Future<void> _saveWord() async {
    if (!_formKey.currentState!.validate()) {
      HapticService.error();
      _announce('El formulario contiene errores. Corrige los campos marcados.');
      return;
    }

    HapticService.buttonPress();
    setState(() {
      _isSaving = true;
    });

    final finalCategory = _isCreatingNewCategory
        ? _newCategoryController.text.trim()
        : _selectedCategory;

    final rawAliases = _aliasesController.text
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    final enWord = _wordEnController.text.trim().toLowerCase();
    final aliases = rawAliases.isEmpty ? [enWord] : rawAliases;
    final phonetic = _phoneticController.text.trim();

    final wordId = widget.isEditing
        ? widget.wordToEdit!.id
        : DateTime.now().millisecondsSinceEpoch.toString();

    final updatedWord = GlossaryWord(
      id: wordId,
      wordEn: enWord,
      wordEs: _wordEsController.text.trim().toLowerCase(),
      category: finalCategory,
      phonetic: phonetic,
      exampleEn: _exampleEnController.text.trim(),
      exampleEs: _exampleEsController.text.trim(),
      aliases: aliases,
      etiquetasIA: aliases,
    );

    try {
      if (widget.isEditing) {
        await GlossaryRepository.updateWord(updatedWord);
        // Actualización atómica con timestamp en Firestore
        try {
          await FirebaseFirestore.instance.collection('glosario_a1').doc(wordId).set({
            ...updatedWord.toFirestore(),
            'fecha_actualizacion': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      } else {
        await GlossaryRepository.addWord(updatedWord);
      }

      await HapticService.success();
      final successMsg = widget.isEditing
          ? 'Palabra "${updatedWord.wordEn}" actualizada exitosamente.'
          : 'Palabra "${updatedWord.wordEn}" agregada exitosamente.';

      _announce(successMsg);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMsg),
          backgroundColor: AppTheme.primary,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      await HapticService.error();
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar en Firestore: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Editar palabra A1' : 'Agregar palabra A1';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: Semantics(
          label: 'Regresar al glosario, botón',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Regresar al glosario',
            onPressed: () {
              HapticService.selection();
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.isEditing
                      ? 'Actualiza los datos del término en el catálogo A1 de Firestore.'
                      : 'Ingresa los datos para registrar una nueva palabra en el catálogo A1.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Campo 1: Palabra en inglés
                Semantics(
                  label: 'Palabra en inglés. Campo de texto obligatorio.',
                  child: TextFormField(
                    controller: _wordEnController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Palabra en inglés *',
                      hintText: 'ej. desk, apple, bottle',
                      prefixIcon: const Icon(Icons.language_rounded, color: AppTheme.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'La palabra en inglés es requerida' : null,
                  ),
                ),
                const SizedBox(height: 18),

                // Campo 2: Traducción en español
                Semantics(
                  label: 'Traducción en español. Campo de texto obligatorio.',
                  child: TextFormField(
                    controller: _wordEsController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Traducción en español *',
                      hintText: 'ej. escritorio, manzana, botella',
                      prefixIcon: const Icon(Icons.translate_rounded, color: AppTheme.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'La traducción es requerida' : null,
                  ),
                ),
                const SizedBox(height: 18),

                // Campo 3: Selector Dinámico de Categorías
                Semantics(
                  label: 'Categoría del vocabulario. Selector de opciones.',
                  child: DropdownButtonFormField<String>(
                    value: _isCreatingNewCategory
                        ? _createNewCategoryValue
                        : (_availableCategories.contains(_selectedCategory) ? _selectedCategory : null),
                    decoration: InputDecoration(
                      labelText: 'Categoría *',
                      prefixIcon: const Icon(Icons.category_rounded, color: AppTheme.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    items: [
                      ..._availableCategories.map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ),
                      ),
                      const DropdownMenuItem(
                        value: _createNewCategoryValue,
                        child: Text(
                          _createNewCategoryValue,
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      HapticService.selection();
                      setState(() {
                        if (val == _createNewCategoryValue) {
                          _isCreatingNewCategory = true;
                        } else {
                          _isCreatingNewCategory = false;
                          _selectedCategory = val;
                        }
                      });
                    },
                    validator: (v) {
                      if (!_isCreatingNewCategory && (v == null || v.isEmpty)) {
                        return 'Selecciona una categoría';
                      }
                      return null;
                    },
                  ),
                ),

                // Campo condicional para nueva categoría
                if (_isCreatingNewCategory) ...[
                  const SizedBox(height: 14),
                  Semantics(
                    label: 'Nombre de la nueva categoría. Campo de texto.',
                    child: TextFormField(
                      controller: _newCategoryController,
                      autofocus: true,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Nombre de la nueva categoría *',
                        hintText: 'ej. Sports, Weather, Office',
                        prefixIcon: const Icon(Icons.add_box_rounded, color: Colors.green),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (v) {
                        if (_isCreatingNewCategory && (v == null || v.trim().isEmpty)) {
                          return 'Ingresa el nombre de la nueva categoría';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // Campo 4: Notación Fonética (IPA) + Botón Generador
                Semantics(
                  label: 'Transcripción fonética IPA. Campo de texto.',
                  child: TextFormField(
                    controller: _phoneticController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Notación fonética (IPA)',
                      hintText: 'ej. /desk/, /æpl/',
                      prefixIcon: const Icon(Icons.record_voice_over_rounded, color: AppTheme.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Botón interactivo: Generar fonética automática
                Semantics(
                  label: 'Generar fonética automática a partir de la palabra en inglés, botón',
                  button: true,
                  hint: 'Toca dos veces para autocompletar la transcripción fonética IPA',
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                    onPressed: _generateAutomaticPhonetic,
                    icon: const Icon(Icons.auto_fix_high_rounded, color: AppTheme.primary),
                    label: const Text(
                      'Generar fonética automática',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Campo 5: Ejemplo en inglés
                Semantics(
                  label: 'Oración de ejemplo en inglés. Campo de texto obligatorio.',
                  child: TextFormField(
                    controller: _exampleEnController,
                    textInputAction: TextInputAction.next,
                    maxLines: 2,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Ejemplo en inglés *',
                      hintText: 'ej. The desk is clean and organized.',
                      prefixIcon: const Icon(Icons.short_text_rounded, color: AppTheme.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'El ejemplo en inglés es requerido' : null,
                  ),
                ),
                const SizedBox(height: 18),

                // Campo 6: Ejemplo en español
                Semantics(
                  label: 'Traducción del ejemplo en español. Campo de texto obligatorio.',
                  child: TextFormField(
                    controller: _exampleEsController,
                    textInputAction: TextInputAction.next,
                    maxLines: 2,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Ejemplo en español *',
                      hintText: 'ej. El escritorio está limpio y ordenado.',
                      prefixIcon: const Icon(Icons.notes_rounded, color: AppTheme.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'El ejemplo en español es requerido' : null,
                  ),
                ),
                const SizedBox(height: 18),

                // Campo 7: Aliases / Etiquetas IA
                Semantics(
                  label: 'Aliases y etiquetas de visión artificial separados por comas.',
                  child: TextFormField(
                    controller: _aliasesController,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Aliases IA (separados por coma)',
                      hintText: 'ej. desk, table, furniture',
                      prefixIcon: const Icon(Icons.tag_rounded, color: AppTheme.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Botón Guardar
                Semantics(
                  label: widget.isEditing
                      ? 'Guardar cambios de la palabra en Firestore, botón'
                      : 'Guardar nueva palabra en Firestore, botón',
                  button: true,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveWord,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _isSaving
                          ? 'Guardando en Firestore...'
                          : (widget.isEditing ? 'Guardar cambios' : 'Guardar palabra'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
