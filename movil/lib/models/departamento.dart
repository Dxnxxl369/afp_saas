// lib/models/departamento.dart
class Departamento {
  final String id;
  final String nombre;
  final String? descripcion;

  Departamento({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  factory Departamento.fromJson(Map<String, dynamic> json) {
    return Departamento(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
    );
  }
}