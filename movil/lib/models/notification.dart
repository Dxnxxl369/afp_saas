// movil/lib/models/notification.dart
import 'package:flutter/foundation.dart'; // For @required if using old Flutter

class Notification {
  final String id;
  final DateTime timestamp;
  final String mensaje;
  final String tipo;
  final bool leido;
  final String? urlDestino;

  Notification({
    required this.id,
    required this.timestamp,
    required this.mensaje,
    required this.tipo,
    this.leido = false,
    this.urlDestino,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mensaje: json['mensaje'] as String,
      tipo: json['tipo'] as String,
      leido: json['leido'] as bool,
      urlDestino: json['url_destino'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'mensaje': mensaje,
      'tipo': tipo,
      'leido': leido,
      'url_destino': urlDestino,
    };
  }

  // Método para crear una copia del objeto con valores modificados
  Notification copyWith({
    String? id,
    DateTime? timestamp,
    String? mensaje,
    String? tipo,
    bool? leido,
    String? urlDestino,
  }) {
    return Notification(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      mensaje: mensaje ?? this.mensaje,
      tipo: tipo ?? this.tipo,
      leido: leido ?? this.leido,
      urlDestino: urlDestino ?? this.urlDestino,
    );
  }

  // Helper to get display name for type
  String get tipoDisplay {
    switch (tipo) {
      case 'ADVERTENCIA':
        return 'Advertencia';
      case 'INFO':
        return 'Información';
      case 'ERROR':
        return 'Error';
      default:
        return 'Notificación';
    }
  }
}
