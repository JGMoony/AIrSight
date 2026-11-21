import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Modelo inmutable de Telemetría / Medición de Sensor para Cloud Firestore.
@immutable
class MeasurementModel {
  final String id;
  final String deviceId;
  final String variable;
  final double valor;
  final String unidad;
  final DateTime timestamp;

  const MeasurementModel({
    required this.id,
    required this.deviceId,
    required this.variable,
    required this.valor,
    required this.unidad,
    required this.timestamp,
  });

  /// Crea un nuevo MeasurementModel modificando los campos indicados.
  MeasurementModel copyWith({
    String? id,
    String? deviceId,
    String? variable,
    double? valor,
    String? unidad,
    DateTime? timestamp,
  }) {
    return MeasurementModel(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      variable: variable ?? this.variable,
      valor: valor ?? this.valor,
      unidad: unidad ?? this.unidad,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convierte la instancia a un Map serializable para Cloud Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'variable': variable,
      'valor': valor,
      'unidad': unidad,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Construye un MeasurementModel desde un Map con parsing robusto de números y fechas.
  factory MeasurementModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return MeasurementModel(
      id: (map['id'] as String?)?.isNotEmpty == true
          ? (map['id'] as String)
          : id,
      deviceId: map['deviceId'] as String? ?? '',
      variable: map['variable'] as String? ?? '',
      valor: _parseDouble(map['valor']),
      unidad: map['unidad'] as String? ?? '',
      timestamp: _parseDateTime(map['timestamp']),
    );
  }

  /// Construye un MeasurementModel a partir de un DocumentSnapshot de Firestore.
  factory MeasurementModel.fromDocumentSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return MeasurementModel.fromMap(data, id: doc.id);
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
      other is MeasurementModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          deviceId == other.deviceId &&
          variable == other.variable &&
          valor == other.valor &&
          unidad == other.unidad &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^
      deviceId.hashCode ^
      variable.hashCode ^
      valor.hashCode ^
      unidad.hashCode ^
      timestamp.hashCode;

  @override
  String toString() {
    return 'MeasurementModel(id: $id, deviceId: $deviceId, variable: $variable, valor: $valor, unidad: $unidad, timestamp: $timestamp)';
  }
}
