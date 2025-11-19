// lib/models/mantenimiento.dart
import 'activo_fijo.dart';
import 'empleado.dart';
import 'mantenimiento_foto.dart';

class Mantenimiento {
  final String id;
  final String tipo;
  final String estado;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String descripcionProblema;
  final String? notasSolucion;
  final double costo;
  final ActivoFijo activo;
  final EmpleadoSimple? empleadoAsignado;
  final List<MantenimientoFoto> fotosProblema;
  final List<MantenimientoFoto> fotosSolucion;

  Mantenimiento({
    required this.id,
    required this.tipo,
    required this.estado,
    required this.fechaInicio,
    this.fechaFin,
    required this.descripcionProblema,
    this.notasSolucion,
    required this.costo,
    required this.activo,
    this.empleadoAsignado,
    this.fotosProblema = const [],
    this.fotosSolucion = const [],
  });

  factory Mantenimiento.fromJson(Map<String, dynamic> json) {
    var fotosProblemaList = json['fotos_problema'] as List? ?? [];
    List<MantenimientoFoto> fotosProblema = fotosProblemaList.map((i) => MantenimientoFoto.fromJson(i)).toList();
    
    var fotosSolucionList = json['fotos_solucion'] as List? ?? [];
    List<MantenimientoFoto> fotosSolucion = fotosSolucionList.map((i) => MantenimientoFoto.fromJson(i)).toList();

    return Mantenimiento(
      id: json['id'],
      tipo: json['tipo'],
      estado: json['estado'],
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: json['fecha_fin'] != null ? DateTime.parse(json['fecha_fin']) : null,
      descripcionProblema: json['descripcion_problema'],
      notasSolucion: json['notas_solucion'],
      costo: double.tryParse(json['costo'].toString()) ?? 0.0,
      activo: ActivoFijo.fromJson(json['activo']),
      empleadoAsignado: json['empleado_asignado'] != null
          ? EmpleadoSimple.fromJson(json['empleado_asignado'])
          : null,
      fotosProblema: fotosProblema,
      fotosSolucion: fotosSolucion,
    );
  }
}
