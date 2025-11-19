// lib/models/mantenimiento_foto.dart

class MantenimientoFoto {
  final String id;
  final String fotoUrl;
  final String tipo;
  final String? subidoPor; // Nombre de usuario de quien subió la foto

  MantenimientoFoto({
    required this.id,
    required this.fotoUrl,
    required this.tipo,
    this.subidoPor,
  });

  factory MantenimientoFoto.fromJson(Map<String, dynamic> json) {
    return MantenimientoFoto(
      id: json['id'],
      fotoUrl: json['foto'],
      tipo: json['tipo'] ?? 'PROBLEMA',
      subidoPor: json['subido_por']?['username'],
    );
  }
}
