// lib/screens/solicitudes_compra/solicitudes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';

import '../../providers/solicitud_compra_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/solicitud_compra.dart';

class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolicitudCompraProvider>().fetchSolicitudes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final canManage = authProvider.hasPermission('manage_solicitud_compra');
    final canApprove = authProvider.hasPermission('approve_solicitud_compra');

    return Scaffold(
      body: Consumer<SolicitudCompraProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.solicitudes.isEmpty) {
            return const Center(child: Text('No hay solicitudes de compra.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchSolicitudes(),
            child: ListView.builder(
              itemCount: provider.solicitudes.length,
              itemBuilder: (context, index) {
                final solicitud = provider.solicitudes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              solicitud.departamentoNombre,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Chip(
                              label: Text(solicitud.estado),
                              backgroundColor: _getStatusColor(solicitud.estado).withOpacity(0.2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(solicitud.descripcion, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Solicitante: ${solicitud.solicitanteNombre}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy').format(solicitud.fechaSolicitud)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (solicitud.estado == 'PENDIENTE' && canApprove)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _showRejectDialog(context, solicitud),
                                  child: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<SolicitudCompraProvider>().aprobarSolicitud(solicitud.id);
                                  },
                                  child: const Text('Aprobar'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Mostrar formulario para crear nueva solicitud
              },
              child: const Icon(Icons.add),
              tooltip: 'Nueva Solicitud',
            )
          : null,
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'APROBADA':
        return Colors.green;
      case 'PENDIENTE':
        return Colors.orange;
      case 'RECHAZADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showRejectDialog(BuildContext context, SolicitudCompra solicitud) {
    final TextEditingController motivoController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Solicitud'),
        content: TextField(
          controller: motivoController,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivoController.text.isNotEmpty) {
                context.read<SolicitudCompraProvider>().rechazarSolicitud(solicitud.id, motivoController.text);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Confirmar Rechazo'),
          ),
        ],
      ),
    );
  }
}
