// movil/lib/models/activo_fijo.dart

class ActivoFijo {
  final String id;
  final String nombre;
  final String codigoInterno;
  final DateTime fechaAdquisicion;
  final double valorActual;
  final int vidaUtil; // Nuevo
  
  final String? departamentoId; // Nuevo
  final String? departamentoNombre;
  
  final String categoriaId; // Nuevo
  final String categoriaNombre;
  
  final String estadoId; // Nuevo
  final String estadoNombre;
  
  final String ubicacionId; // Nuevo
  final String? ubicacionNombre; // Nuevo
  
  final String? proveedorId; // Nuevo
  final String? proveedorNombre; // Nuevo
  
  final String? fotoActivoUrl;

  ActivoFijo({
    required this.id,
    required this.nombre,
    required this.codigoInterno,
    required this.fechaAdquisicion,
    required this.valorActual,
    required this.vidaUtil, // Nuevo
    
    this.departamentoId, // Nuevo
    this.departamentoNombre,
    
    required this.categoriaId, // Nuevo
    required this.categoriaNombre,
    
    required this.estadoId, // Nuevo
    required this.estadoNombre,
    
    required this.ubicacionId, // Nuevo
    this.ubicacionNombre, // Nuevo
    
    this.proveedorId, // Nuevo
    this.proveedorNombre, // Nuevo
    
    this.fotoActivoUrl,
  });

  factory ActivoFijo.fromJson(Map<String, dynamic> json) {
    return ActivoFijo(
      id: json['id'],
      nombre: json['nombre'],
      codigoInterno: json['codigo_interno'],
      fechaAdquisicion: DateTime.parse(json['fecha_adquisicion']),
      valorActual: (json['valor_actual'] as num).toDouble(),
      vidaUtil: json['vida_util'], // Nuevo
      
      departamentoId: json['departamento'], // Nuevo
      departamentoNombre: json['departamento_detail']?['nombre'],
      
      categoriaId: json['categoria'], // Nuevo
      categoriaNombre: json['categoria_detail']?['nombre'] ?? 'Sin categoría',
      
      estadoId: json['estado'], // Nuevo
      estadoNombre: json['estado_detail']?['nombre'] ?? 'Sin estado',
      
      ubicacionId: json['ubicacion'], // Nuevo
      ubicacionNombre: json['ubicacion_detail']?['nombre'], // Nuevo
      
      proveedorId: json['proveedor'], // Nuevo
      proveedorNombre: json['proveedor_detail']?['nombre'], // Nuevo
      
      fotoActivoUrl: json['foto_activo'],
    );
  }
}
