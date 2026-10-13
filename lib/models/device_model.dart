import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Modelo inmutable de Dispositivo IoT para Cloud Firestore (Colección 'dispositivos').
@immutable
class DeviceModel {
  final String id;
  final String codigoSerie;
  final String nombre;
  final String estado;
  final String userIdAsociado;
  final DateTime ultimaConexion;

  const DeviceModel({
    required this.id,
    required this.codigoSerie,
    required this.nombre,
    required this.estado,
    required this.userIdAsociado,
    required this.ultimaConexion,
  });

  /// Crea un nuevo DeviceModel modificando los campos indicados.
  DeviceModel copyWith({
    String? id,
    String? codigoSerie,
    String? nombre,
    String? estado,
    String? userIdAsociado,
    DateTime? ultimaConexion,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      codigoSerie: codigoSerie ?? this.codigoSerie,
      nombre: nombre ?? this.nombre,
      estado: estado ?? this.estado,
      userIdAsociado: userIdAsociado ?? this.userIdAsociado,
      ultimaConexion: ultimaConexion ?? this.ultimaConexion,
    );
  }

  /// Convierte la instancia a un Map serializable para Cloud Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigoSerie': codigoSerie,
      'nombre': nombre,
      'estado': estado,
      'userIdAsociado': userIdAsociado,
      'ultimaConexion': Timestamp.fromDate(ultimaConexion),
    };
  }

  /// Construye un DeviceModel desde un Map con parsing robusto de fechas y campos nulos.
  factory DeviceModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return DeviceModel(
      id: (map['id'] as String?)?.isNotEmpty == true
          ? (map['id'] as String)
          : id,
      codigoSerie: map['codigoSerie'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      estado: map['estado'] as String? ?? 'inactivo',
      userIdAsociado: map['userIdAsociado'] as String? ?? '',
      ultimaConexion: _parseDateTime(map['ultimaConexion']),
    );
  }

  /// Construye un DeviceModel a partir de un DocumentSnapshot de Firestore.
  factory DeviceModel.fromDocumentSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DeviceModel.fromMap(data, id: doc.id);
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
      other is DeviceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          codigoSerie == other.codigoSerie &&
          nombre == other.nombre &&
          estado == other.estado &&
          userIdAsociado == other.userIdAsociado &&
          ultimaConexion == other.ultimaConexion;

  @override
  int get hashCode =>
      id.hashCode ^
      codigoSerie.hashCode ^
      nombre.hashCode ^
      estado.hashCode ^
      userIdAsociado.hashCode ^
      ultimaConexion.hashCode;

  @override
  String toString() {
    return 'DeviceModel(id: $id, codigoSerie: $codigoSerie, nombre: $nombre, estado: $estado, userIdAsociado: $userIdAsociado, ultimaConexion: $ultimaConexion)';
  }
}
