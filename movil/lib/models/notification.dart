// movil/lib/models/notification.dart
import 'package:flutter/foundation.dart'; // For @required if using old Flutter

class Notification {
  final String id;
  final DateTime timestamp;
  final String mensaje;
  final String tipo; // e.g., 'INFO', 'ADVERTENCIA', 'ERROR'
  bool leido; // This will be mutable as its status changes
  final String? urlDestino; // e.g., '/app/mantenimientos'

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

  // Helper to get display name for type (similar to Django's get_tipo_display)
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
