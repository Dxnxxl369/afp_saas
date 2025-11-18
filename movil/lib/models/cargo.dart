// lib/models/cargo.dart

class Cargo {
  final String id;
  final String nombre;
  final String? descripcion;

  Cargo({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  factory Cargo.fromJson(Map<String, dynamic> json) {
    return Cargo(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
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
