// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';

import '../../providers/dashboard_provider.dart';
import '../../providers/provider_state.dart';
import '../../models/dashboard_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      if (provider.loadingState == LoadingState.idle) {
        provider.fetchDashboardData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.loadingState == LoadingState.loading && provider.dashboardData == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.loadingState == LoadingState.error) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }
          if (provider.dashboardData == null) {
            return const Center(child: Text('No hay datos para mostrar.'));
          }

          final data = provider.dashboardData!;
          final currencyFormat = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs. ');

          return RefreshIndicator(
            onRefresh: provider.fetchDashboardData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16.0,
                    runSpacing: 16.0,
                    children: [
                      _StatCard(
                        icon: LucideIcons.archive,
                        label: 'Total de Activos',
                        value: data.totalActivos.toString(),
                        color: Colors.blue,
                      ),
                      _StatCard(
                        icon: LucideIcons.chartBar,
                        label: 'Valor Total de Activos',
                        value: currencyFormat.format(data.valorTotalActivos),
                        color: Colors.green,
                      ),
                      _StatCard(
                        icon: LucideIcons.users,
                        label: 'Total de Usuarios',
                        value: data.totalUsuarios.toString(),
                        color: Colors.orange,
                      ),
                      _StatCard(
                        icon: LucideIcons.shoppingCart,
                        label: 'Solicitudes Pendientes',
                        value: data.solicitudesPendientes.toString(),
                        color: Colors.purple,
                      ),
                       _StatCard(
                        icon: LucideIcons.wrench,
                        label: 'Mantenimientos en Proceso',
                        value: data.mantenimientosEnProceso.toString(),
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (data.activosPorEstado.isNotEmpty)
                    _PieChartCard(
                      title: 'Activos por Estado',
                      data: data.activosPorEstado,
                    ),
                  const SizedBox(height: 16),
                   if (data.activosPorCategoria.isNotEmpty)
                    _PieChartCard(
                      title: 'Activos por Categoría',
                      data: data.activosPorCategoria,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 24,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PieChartCard extends StatefulWidget {
  final String title;
  final List<ChartDataPoint> data;

  const _PieChartCard({required this.title, required this.data});

  @override
  State<_PieChartCard> createState() => _PieChartCardState();
}

class _PieChartCardState extends State<_PieChartCard> {
  int touchedIndex = -1;

  // Generate a list of colors for the chart
  final List<Color> _chartColors = [
    Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red,
    Colors.teal, Colors.pink, Colors.amber, Colors.cyan, Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: List.generate(widget.data.length, (i) {
                    final isTouched = i == touchedIndex;
                    final fontSize = isTouched ? 16.0 : 12.0;
                    final radius = isTouched ? 60.0 : 50.0;
                    final color = _chartColors[i % _chartColors.length];

                    return PieChartSectionData(
                      color: color,
                      value: widget.data[i].count.toDouble(),
                      title: '${widget.data[i].count}',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: List.generate(widget.data.length, (i) {
                final color = _chartColors[i % _chartColors.length];
                return _Indicator(
                  color: color,
                  text: widget.data[i].name,
                  isSquare: false,
                  size: touchedIndex == i ? 18 : 16,
                  textColor: touchedIndex == i ? Colors.black : Colors.grey,
                );
              }),
            )
          ],
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;

  const _Indicator({
    required this.color,
    required this.text,
    this.isSquare = true,
    this.size = 16,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        )
      ],
    );
  }
}
