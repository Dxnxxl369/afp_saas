// movil/lib/models/permiso.dart
class Permiso {
  final String id;
  final String nombre;
  final String descripcion;

  Permiso({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  factory Permiso.fromJson(Map<String, dynamic> json) {
    return Permiso(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }
}
