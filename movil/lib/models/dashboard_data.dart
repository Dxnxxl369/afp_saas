// lib/models/dashboard_data.dart

class ChartDataPoint {
  final String name;
  final int count;

  ChartDataPoint({required this.name, required this.count});

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    // The backend sends keys like 'estado__nombre' or 'categoria__nombre'
    final key = json.keys.firstWhere((k) => k.endsWith('__nombre'), orElse: () => 'name');
    return ChartDataPoint(
      name: json[key] ?? 'Desconocido',
      count: json['count'] ?? 0, // Handle null count
    );
  }
}

class DashboardData {
  final int totalActivos;
  final int totalUsuarios;
  final double valorTotalActivos;
  final int solicitudesPendientes;
  final int mantenimientosEnProceso;
  final List<ChartDataPoint> activosPorEstado;
  final List<ChartDataPoint> activosPorCategoria;

  DashboardData({
    required this.totalActivos,
    required this.totalUsuarios,
    required this.valorTotalActivos,
    required this.solicitudesPendientes,
    required this.mantenimientosEnProceso,
    required this.activosPorEstado,
    required this.activosPorCategoria,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    var estadosList = (json['activos_por_estado'] as List? ?? []).map((i) => ChartDataPoint.fromJson(i)).toList();
    var categoriasList = (json['activos_por_categoria'] as List? ?? []).map((i) => ChartDataPoint.fromJson(i)).toList();

    return DashboardData(
      totalActivos: json['total_activos'] ?? 0,
      totalUsuarios: json['total_usuarios'] ?? 0,
      valorTotalActivos: double.tryParse(json['valor_total_activos'].toString()) ?? 0.0,
      solicitudesPendientes: json['solicitudes_pendientes'] ?? 0,
      mantenimientosEnProceso: json['mantenimientos_en_proceso'] ?? 0,
      activosPorEstado: estadosList,
      activosPorCategoria: categoriasList,
    );
  }
}
