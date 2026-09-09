import 'package:flutter/material.dart';

import 'glossary_category.dart';
import 'glossary_word.dart';

const List<GlossaryCategory> glossaryCategories = [
  GlossaryCategory(name: 'Animals', icon: Icons.pets_rounded, color: Color(0xFF795548)),
  GlossaryCategory(name: 'Body', icon: Icons.accessibility_new_rounded, color: Color(0xFFFF5722)),
  GlossaryCategory(name: 'Classroom', icon: Icons.school_rounded, color: Color(0xFF4CAF50)),
  GlossaryCategory(name: 'Clothes', icon: Icons.checkroom_rounded, color: Color(0xFF607D8B)),
  GlossaryCategory(name: 'Colors', icon: Icons.palette_rounded, color: Color(0xFF9C27B0)),
  GlossaryCategory(name: 'Family', icon: Icons.family_restroom_rounded, color: Color(0xFFAB47BC)),
  GlossaryCategory(name: 'Food', icon: Icons.restaurant_rounded, color: Color(0xFFE91E63)),
  GlossaryCategory(name: 'Home', icon: Icons.home_rounded, color: Color(0xFFFF9800)),
  GlossaryCategory(name: 'Jobs', icon: Icons.work_rounded, color: Color(0xFF455A64)),
  GlossaryCategory(name: 'Kitchen', icon: Icons.kitchen_rounded, color: Color(0xFFFF7043)),
  GlossaryCategory(name: 'Nature', icon: Icons.park_rounded, color: Color(0xFF66BB6A)),
  GlossaryCategory(name: 'Numbers', icon: Icons.numbers_rounded, color: Color(0xFF2196F3)),
  GlossaryCategory(name: 'Objects', icon: Icons.category_rounded, color: Color(0xFF26A69A)),
  GlossaryCategory(name: 'People', icon: Icons.people_rounded, color: Color(0xFF3F51B5)),
  GlossaryCategory(name: 'Places', icon: Icons.location_city_rounded, color: Color(0xFF009688)),
  GlossaryCategory(name: 'School Actions', icon: Icons.edit_note_rounded, color: Color(0xFF7E57C2)),
  GlossaryCategory(name: 'Technology', icon: Icons.devices_rounded, color: Color(0xFF00ACC1)),
  GlossaryCategory(name: 'Time', icon: Icons.access_time_rounded, color: Color(0xFF5E35B1)),
  GlossaryCategory(name: 'Transport', icon: Icons.directions_bus_rounded, color: Color(0xFFFFB300)),
  GlossaryCategory(name: 'Weather', icon: Icons.wb_sunny_rounded, color: Color(0xFF29B6F6)),
];

const List<GlossaryWord> glossaryWords = [
  // Animals
  GlossaryWord(id: '1', wordEn: 'bird', wordEs: 'pájaro', category: 'Animals', example: 'The bird is small.', exampleEs: 'El pájaro es pequeño.', aliases: ['bird', 'animal']),
  GlossaryWord(id: '2', wordEn: 'cat', wordEs: 'gato', category: 'Animals', example: 'The cat is sleeping.', exampleEs: 'El gato está durmiendo.', aliases: ['cat', 'animal']),
  GlossaryWord(id: '3', wordEn: 'cow', wordEs: 'vaca', category: 'Animals', example: 'The cow is big.', exampleEs: 'La vaca es grande.', aliases: ['cow', 'animal']),
  GlossaryWord(id: '4', wordEn: 'dog', wordEs: 'perro', category: 'Animals', example: 'The dog is friendly.', exampleEs: 'El perro es amigable.', aliases: ['dog', 'animal']),
  GlossaryWord(id: '5', wordEn: 'duck', wordEs: 'pato', category: 'Animals', example: 'The duck is in the water.', exampleEs: 'El pato está en el agua.', aliases: ['duck', 'animal']),
  GlossaryWord(id: '6', wordEn: 'fish', wordEs: 'pez', category: 'Animals', example: 'The fish is blue.', exampleEs: 'El pez es azul.', aliases: ['fish', 'animal']),
  GlossaryWord(id: '7', wordEn: 'horse', wordEs: 'caballo', category: 'Animals', example: 'The horse runs fast.', exampleEs: 'El caballo corre rápido.', aliases: ['horse', 'animal']),
  GlossaryWord(id: '8', wordEn: 'lion', wordEs: 'león', category: 'Animals', example: 'The lion is strong.', exampleEs: 'El león es fuerte.', aliases: ['lion', 'animal']),
  GlossaryWord(id: '9', wordEn: 'mouse', wordEs: 'ratón', category: 'Animals', example: 'The mouse is small.', exampleEs: 'El ratón es pequeño.', aliases: ['mouse', 'animal']),
  GlossaryWord(id: '10', wordEn: 'pig', wordEs: 'cerdo', category: 'Animals', example: 'The pig is pink.', exampleEs: 'El cerdo es rosado.', aliases: ['pig', 'animal']),
  GlossaryWord(id: '11', wordEn: 'rabbit', wordEs: 'conejo', category: 'Animals', example: 'The rabbit is white.', exampleEs: 'El conejo es blanco.', aliases: ['rabbit', 'animal']),
  GlossaryWord(id: '12', wordEn: 'sheep', wordEs: 'oveja', category: 'Animals', example: 'The sheep is quiet.', exampleEs: 'La oveja está tranquila.', aliases: ['sheep', 'animal']),
  GlossaryWord(id: '13', wordEn: 'tiger', wordEs: 'tigre', category: 'Animals', example: 'The tiger is orange.', exampleEs: 'El tigre es naranja.', aliases: ['tiger', 'animal']),
  GlossaryWord(id: '14', wordEn: 'turtle', wordEs: 'tortuga', category: 'Animals', example: 'The turtle is slow.', exampleEs: 'La tortuga es lenta.', aliases: ['turtle', 'animal']),
  GlossaryWord(id: '15', wordEn: 'zebra', wordEs: 'cebra', category: 'Animals', example: 'The zebra is black and white.', exampleEs: 'La cebra es negra y blanca.', aliases: ['zebra', 'animal']),

  // Classroom
  GlossaryWord(id: '16', wordEn: 'bag', wordEs: 'bolso', category: 'Classroom', example: 'My bag is on the chair.', exampleEs: 'Mi bolso está sobre la silla.', aliases: ['bag', 'backpack']),
  GlossaryWord(id: '17', wordEn: 'board', wordEs: 'tablero', category: 'Classroom', example: 'The teacher writes on the board.', exampleEs: 'El profesor escribe en el tablero.', aliases: ['board', 'whiteboard', 'blackboard']),
  GlossaryWord(id: '18', wordEn: 'book', wordEs: 'libro', category: 'Classroom', example: 'I have a new book.', exampleEs: 'Tengo un libro nuevo.', aliases: ['book', 'textbook']),
  GlossaryWord(id: '19', wordEn: 'chair', wordEs: 'silla', category: 'Classroom', example: 'This is a chair.', exampleEs: 'Esta es una silla.', aliases: ['chair', 'seat', 'furniture']),
  GlossaryWord(id: '20', wordEn: 'classroom', wordEs: 'salón de clase', category: 'Classroom', example: 'The classroom is clean.', exampleEs: 'El salón de clase está limpio.', aliases: ['classroom', 'room']),
  GlossaryWord(id: '21', wordEn: 'desk', wordEs: 'escritorio', category: 'Classroom', example: 'The desk is brown.', exampleEs: 'El escritorio es marrón.', aliases: ['desk', 'table']),
  GlossaryWord(id: '22', wordEn: 'eraser', wordEs: 'borrador', category: 'Classroom', example: 'The eraser is small.', exampleEs: 'El borrador es pequeño.', aliases: ['eraser']),
  GlossaryWord(id: '23', wordEn: 'marker', wordEs: 'marcador', category: 'Classroom', example: 'The marker is red.', exampleEs: 'El marcador es rojo.', aliases: ['marker']),
  GlossaryWord(id: '24', wordEn: 'notebook', wordEs: 'cuaderno', category: 'Classroom', example: 'My notebook is blue.', exampleEs: 'Mi cuaderno es azul.', aliases: ['notebook', 'book']),
  GlossaryWord(id: '25', wordEn: 'paper', wordEs: 'papel', category: 'Classroom', example: 'The paper is white.', exampleEs: 'El papel es blanco.', aliases: ['paper', 'sheet']),
  GlossaryWord(id: '26', wordEn: 'pen', wordEs: 'bolígrafo', category: 'Classroom', example: 'This is my pen.', exampleEs: 'Este es mi bolígrafo.', aliases: ['pen', 'ballpoint pen']),
  GlossaryWord(id: '27', wordEn: 'pencil', wordEs: 'lápiz', category: 'Classroom', example: 'The pencil is yellow.', exampleEs: 'El lápiz es amarillo.', aliases: ['pencil']),
  GlossaryWord(id: '28', wordEn: 'ruler', wordEs: 'regla', category: 'Classroom', example: 'The ruler is long.', exampleEs: 'La regla es larga.', aliases: ['ruler']),
  GlossaryWord(id: '29', wordEn: 'schoolbag', wordEs: 'maleta escolar', category: 'Classroom', example: 'The schoolbag is heavy.', exampleEs: 'La maleta escolar es pesada.', aliases: ['schoolbag', 'backpack']),
  GlossaryWord(id: '30', wordEn: 'table', wordEs: 'mesa', category: 'Classroom', example: 'The book is on the table.', exampleEs: 'El libro está sobre la mesa.', aliases: ['table', 'desk', 'furniture']),
];