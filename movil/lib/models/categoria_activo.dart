// lib/models/categoria_activo.dart

class CategoriaActivo {
  final String id;
  final String nombre;
  final String? descripcion;

  CategoriaActivo({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  factory CategoriaActivo.fromJson(Map<String, dynamic> json) {
    return CategoriaActivo(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
    );
  }
}
