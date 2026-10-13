import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Modelo inmutable de Usuario para Cloud Firestore (Colección 'users').
/// Estándar canónico único: `uid`, `email`, `nombre`, `rol`, `fechaRegistro`.
@immutable
class UserModel {
  final String uid;
  final String email;
  final String nombre;
  final String rol; // 'administrador' | 'estudiante'
  final DateTime fechaRegistro;

  /// Alias de compatibilidad hacia [uid].
  String get id => uid;

  const UserModel({
    String? id,
    String? uid,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.fechaRegistro,
  }) : uid = (uid != null && uid != '')
            ? uid
            : ((id != null && id != '') ? id : '');

  /// Retorna el rol normalizado ('administrador' o 'estudiante').
  String get canonicalRole {
    final clean = rol.trim().toLowerCase();
    return (clean == 'admin' || clean == 'administrador')
        ? 'administrador'
        : 'estudiante';
  }

  /// Indica si el usuario tiene rol de Administrador ('administrador' o 'admin').
  bool get isAdmin => canonicalRole == 'administrador';

  /// Indica si el usuario tiene rol de Estudiante ('estudiante' o 'student').
  bool get isStudent => canonicalRole == 'estudiante';

  /// Etiqueta clara del rol para la interfaz de usuario.
  String get roleLabel => isAdmin ? 'Administrador del Sistema' : 'Estudiante';

  /// Crea un nuevo UserModel modificando los campos indicados.
  UserModel copyWith({
    String? uid,
    String? id,
    String? email,
    String? nombre,
    String? rol,
    DateTime? fechaRegistro,
  }) {
    return UserModel(
      uid: uid ?? id ?? this.uid,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  /// Convierte la instancia al formato canónico estandarizado y limpio para Firestore.
  /// Contiene estrictamente los 5 campos oficiales: uid, email, nombre, rol, fechaRegistro.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email.trim().toLowerCase(),
      'nombre': nombre.trim(),
      'rol': canonicalRole,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
    };
  }

  /// Construye un UserModel desde un Map con parsing robusto de fechas y migración de campos legados.
  factory UserModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    final docUid = (map['uid'] as String?)?.isNotEmpty == true
        ? (map['uid'] as String)
        : ((map['id'] as String?)?.isNotEmpty == true
            ? (map['id'] as String)
            : id);

    final rawName = (map['nombre'] as String?)?.isNotEmpty == true
        ? (map['nombre'] as String)
        : (map['name'] as String? ?? '');

    final rawEmail = (map['email'] as String? ?? '').trim().toLowerCase();

    final rawRole = (map['rol'] as String?)?.isNotEmpty == true
        ? (map['rol'] as String)
        : (map['role'] as String? ?? 'estudiante');

    final cleanRole = (rawRole.trim().toLowerCase() == 'admin' ||
            rawRole.trim().toLowerCase() == 'administrador')
        ? 'administrador'
        : 'estudiante';

    return UserModel(
      uid: docUid,
      email: rawEmail,
      nombre: rawName,
      rol: cleanRole,
      fechaRegistro: _parseDateTime(map['fechaRegistro'] ?? map['createdAt']),
    );
  }

  /// Construye un UserModel a partir de un DocumentSnapshot de Firestore.
  factory UserModel.fromDocumentSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return UserModel.fromMap(data, id: doc.id);
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          nombre == other.nombre &&
          canonicalRole == other.canonicalRole &&
          fechaRegistro == other.fechaRegistro;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      nombre.hashCode ^
      canonicalRole.hashCode ^
      fechaRegistro.hashCode;

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, nombre: $nombre, rol: $canonicalRole, fechaRegistro: $fechaRegistro)';
  }
}
