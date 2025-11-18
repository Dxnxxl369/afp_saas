// lib/models/estado.dart

class Estado {
  final String id;
  final String nombre;
  final String? detalle;

  Estado({
    required this.id,
    required this.nombre,
    this.detalle,
  });

  factory Estado.fromJson(Map<String, dynamic> json) {
    return Estado(
      id: json['id'],
      nombre: json['nombre'],
      detalle: json['detalle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'detalle': detalle,
    };
  }
}
