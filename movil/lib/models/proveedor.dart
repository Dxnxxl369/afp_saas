// lib/models/proveedor.dart

class Proveedor {
  final String id;
  final String nombre;
  final String nit;
  final String? email;
  final String? telefono;
  final String? pais;
  final String? direccion;
  final String estado;

  Proveedor({
    required this.id,
    required this.nombre,
    required this.nit,
    this.email,
    this.telefono,
    this.pais,
    this.direccion,
    required this.estado,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'],
      nombre: json['nombre'],
      nit: json['nit'],
      email: json['email'],
      telefono: json['telefono'],
      pais: json['pais'],
      direccion: json['direccion'],
      estado: json['estado'],
    );
  }
}
