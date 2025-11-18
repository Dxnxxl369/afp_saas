// lib/models/ubicacion.dart

class Ubicacion {
  final String id;
  final String nombre;
  final String? direccion;
  final String? detalle;

  Ubicacion({
    required this.id,
    required this.nombre,
    this.direccion,
    this.detalle,
  });

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      id: json['id'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      detalle: json['detalle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'detalle': detalle,
    };
  }
}
