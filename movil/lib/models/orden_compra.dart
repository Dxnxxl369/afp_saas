// movil/lib/models/orden_compra.dart

class OrdenCompra {
  final String id;
  final String estado;
  final double precioFinal;
  final DateTime fechaOrden;
  final String proveedorNombre;
  final String solicitudDescripcion; // Para tener contexto

  OrdenCompra({
    required this.id,
    required this.estado,
    required this.precioFinal,
    required this.fechaOrden,
    required this.proveedorNombre,
    required this.solicitudDescripcion,
  });

  factory OrdenCompra.fromJson(Map<String, dynamic> json) {
    return OrdenCompra(
      id: json['id'],
      estado: json['estado'] ?? 'DESCONOCIDO',
      precioFinal: double.tryParse(json['precio_final'].toString()) ?? 0.0,
      fechaOrden: DateTime.parse(json['fecha_orden']),
      proveedorNombre: json['proveedor_detail']?['nombre'] ?? 'N/A',
      solicitudDescripcion: json['solicitud_detail']?['descripcion'] ?? 'N/A',
    );
  }
}
