// lib/screens/presupuesto/partidas_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../providers/presupuesto_provider.dart';
import '../../models/periodo_presupuestario.dart';

class PartidasScreen extends StatefulWidget {
  final PeriodoPresupuestario periodo;

  const PartidasScreen({super.key, required this.periodo});

  @override
  State<PartidasScreen> createState() => _PartidasScreenState();
}

class _PartidasScreenState extends State<PartidasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresupuestoProvider>().fetchPartidas(widget.periodo.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partidas de ${widget.periodo.nombre}'),
      ),
      body: Consumer<PresupuestoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingPartidas) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorPartidas != null) {
            return Center(child: Text('Error: ${provider.errorPartidas}'));
          }

          if (provider.partidas.isEmpty) {
            return const Center(child: Text('No hay partidas para este período.'));
          }

          return ListView.builder(
            itemCount: provider.partidas.length,
            itemBuilder: (context, index) {
              final partida = provider.partidas[index];
              final double percentUsed = partida.montoAsignado > 0
                  ? partida.montoGastado / partida.montoAsignado
                  : 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partida.nombre,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (partida.departamento != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            partida.departamento!.nombre,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Gastado: \$${partida.montoGastado.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          Text(
                            'Asignado: \$${partida.montoAsignado.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentUsed,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentUsed > 0.9 ? Colors.red : (percentUsed > 0.7 ? Colors.orange : Colors.green),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Disponible: \$${partida.montoDisponible.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // TODO: Añadir FAB para crear nuevas partidas
    );
  }
}
