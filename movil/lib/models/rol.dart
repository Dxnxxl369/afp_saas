// movil/lib/models/rol.dart
import 'permiso.dart'; // Import the Permiso model

class Rol {
  final String id;
  final String nombre;
  final String? empresaId; // Make nullable
  final List<Permiso> permisos;

  Rol({
    required this.id,
    required this.nombre,
    this.empresaId, // Now nullable
    this.permisos = const [],
  });

  factory Rol.fromJson(Map<String, dynamic> json) {
    var permisosList = json['permisos'] as List?; // Changed key from 'permisos_asignados'
    List<Permiso> parsedPermisos = permisosList != null
        ? permisosList.map((i) => Permiso.fromJson(i)).toList()
        : [];

    return Rol(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      empresaId: json['empresa'] as String?, // Make nullable
      permisos: parsedPermisos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'empresa': empresaId,
      'permisos': permisos.map((p) => p.toJson()).toList(), // Only IDs needed for sending
    };
  }

  // Helper to check if a role has a specific permission
  bool hasPermission(String permissionName) {
    return permisos.any((permiso) => permiso.nombre == permissionName);
  }
}
