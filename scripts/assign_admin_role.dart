import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'package:air_sight/firebase_options.dart';
import 'package:air_sight/services/firestore_service.dart';

/// Script de utilidad para asignar el rol de Administrador a un UID específico.
/// Uso desde la terminal:
///   `dart run scripts/assign_admin_role.dart [UID]`
/// O sin argumentos para asignar a la cuenta predeterminada del equipo de grado.
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  stdout.writeln('==============================================');
  stdout.writeln('    Air Sight: Asignador de Rol Administrador  ');
  stdout.writeln('==============================================');

  final targetUid = args.isNotEmpty ? args[0] : 'admin_default_uid';
  final targetRole = args.length > 1 ? args[1] : 'administrador';

  stdout.writeln('Inicializando Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  stdout.writeln('Asignando rol "$targetRole" al UID: $targetUid ...');
  try {
    await FirestoreService.instance.setUserRole(
      userId: targetUid,
      role: targetRole,
    );
    stdout.writeln('¡Éxito! El usuario con UID "$targetUid" ahora tiene el rol "$targetRole".');
  } catch (e) {
    stderr.writeln('Error al actualizar rol en Firestore: $e');
    exit(1);
  }

  exit(0);
}
