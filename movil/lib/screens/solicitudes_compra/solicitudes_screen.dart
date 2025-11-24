// lib/screens/solicitudes_compra/solicitudes_screen.dart
import 'dart:async'; // Necesario para Timer si se usa para el debounce o loaders
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';

import '../../providers/solicitud_compra_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/departamento_provider.dart';
import '../../providers/presupuesto_provider.dart';
import '../../models/solicitud_compra.dart';
import '../../models/departamento.dart';
import '../../models/partida_presupuestaria.dart';
import '../../models/periodo_presupuestario.dart';
import '../../providers/provider_state.dart';

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
      _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([
      context.read<SolicitudCompraProvider>().fetchSolicitudes(),
      context.read<DepartamentoProvider>().fetchDepartamentos(),
      context.read<PresupuestoProvider>().fetchPeriodos(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final canCreate = authProvider.hasPermission('add_solicitud_compra') || authProvider.hasPermission('manage_solicitud_compra');
    final canApprove = authProvider.hasPermission('approve_solicitud_compra');

    return Scaffold(
      body: Consumer<SolicitudCompraProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.solicitudes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.solicitudes.isEmpty) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          if (provider.solicitudes.isEmpty) {
            return const Center(child: Text('No hay solicitudes de compra.'));
          }
          return RefreshIndicator(
            onRefresh: _fetchInitialData,
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
                            Expanded(
                              child: Text(
                                solicitud.departamentoNombre ?? 'N/A', // Usar 'N/A' si es nulo
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Chip(
                              label: Text(solicitud.estado.replaceAll('_', ' ')),
                              backgroundColor: _getStatusColor(solicitud.estado).withOpacity(0.2),
                              labelStyle: TextStyle(color: _getStatusColor(solicitud.estado)),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(solicitud.descripcion, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildInfoRow(LucideIcons.user, 'Solicitante:', solicitud.solicitanteNombre ?? 'N/A'),
                        _buildInfoRow(LucideIcons.dollarSign, 'Costo Estimado:', NumberFormat.currency(locale: 'es_BO', symbol: 'Bs ').format(solicitud.costoEstimado)),
                        _buildInfoRow(LucideIcons.calendar, 'Fecha:', DateFormat('dd/MM/yyyy').format(solicitud.fechaSolicitud)),
                        
                        if (solicitud.estado == 'PENDIENTE' && canApprove)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(LucideIcons.x),
                                  onPressed: () => _showRejectDialog(context, solicitud),
                                  label: const Text('Rechazar'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(LucideIcons.check),
                                  onPressed: () => context.read<SolicitudCompraProvider>().aprobarSolicitud(solicitud.id),
                                  label: const Text('Aprobar'),
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
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => _showCreateSolicitudDialog(context),
              tooltip: 'Nueva Solicitud',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'APROBADA': return Colors.green;
      case 'PENDIENTE': return Colors.orange;
      case 'RECHAZADA': return Colors.red;
      default: return Colors.grey;
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
          decoration: const InputDecoration(labelText: 'Motivo del rechazo', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
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

  void _showCreateSolicitudDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final descripcionController = TextEditingController();
    final costoEstimadoController = TextEditingController();
    String? selectedDepartamentoId;
    String? selectedPartidaId;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final departamentoProvider = Provider.of<DepartamentoProvider>(context, listen: false);
        final presupuestoProvider = Provider.of<PresupuestoProvider>(context, listen: false);
        
        // Inicializar cargas si no están activas
        if (departamentoProvider.loadingState == LoadingState.idle) departamentoProvider.fetchDepartamentos();
        if (presupuestoProvider.isLoadingPeriodos == false) presupuestoProvider.fetchPeriodos();

        final isLoading = ValueNotifier<bool>(false);

        // --- Helper para cargar partidas filtradas ---
        // Este FutureBuilder nos permite esperar por los datos del provider
        // y se reconstruye cuando cambian (ej. al seleccionar un departamento).
        return AlertDialog(
          title: const Text('Crear Solicitud de Compra'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              Future<void> _fetchPartidasFiltered({String? departamentoId}) async {
                if (presupuestoProvider.periodos.isEmpty) return; // No hay períodos para filtrar

                // Por simplicidad, usaremos el primer período disponible si no hay uno seleccionado.
                // En una app real, podrías tener un dropdown para seleccionar el período activo.
                final String periodoId = presupuestoProvider.periodos.first.id;
                
                // Asegúrate de notificar a los listeners del provider para que la UI se actualice
                await presupuestoProvider.fetchPartidas(periodoId, departamentoId: departamentoId);
                setState(() {
                  selectedPartidaId = null; // Resetear la partida seleccionada
                });
              }

              // Llamada inicial para cargar partidas si ya hay períodos
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (selectedDepartamentoId == null && presupuestoProvider.periodos.isNotEmpty && !presupuestoProvider.isLoadingPartidas) {
                   _fetchPartidasFiltered(departamentoId: null); // Cargar todas las partidas del período por defecto
                }
              });


              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(controller: descripcionController, decoration: const InputDecoration(labelText: 'Descripción'), validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null, maxLines: 3),
                      const SizedBox(height: 16),
                      TextFormField(controller: costoEstimadoController, decoration: const InputDecoration(labelText: 'Costo Estimado'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) { if (v == null || v.isEmpty) return 'Requerido'; if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Costo inválido'; return null; }),
                      const SizedBox(height: 16),
                      Consumer<DepartamentoProvider>(
                        builder: (context, provider, _) {
                          if (provider.loadingState == LoadingState.loading) return const Center(child: CircularProgressIndicator());
                          return DropdownButtonFormField<String>(
                            value: selectedDepartamentoId,
                            decoration: const InputDecoration(labelText: 'Departamento'),
                            items: provider.departamentos.map((dep) => DropdownMenuItem<String>(value: dep.id, child: Text(dep.nombre))).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedDepartamentoId = value;
                                // Recargar/filtrar partidas cuando cambia el departamento
                                if (value != null) {
                                   _fetchPartidasFiltered(departamentoId: value);
                                } else {
                                   // Si no se selecciona departamento, mostrar todas las partidas del período
                                   _fetchPartidasFiltered(departamentoId: null);
                                }
                              });
                            },
                            validator: (value) => value == null ? 'Requerido' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<PresupuestoProvider>(
                        builder: (context, provider, _) {
                          if (provider.isLoadingPeriodos) return const Center(child: CircularProgressIndicator());
                          final partidas = provider.partidas; // Ahora vienen filtradas por el provider
                          return DropdownButtonFormField<String>(
                            value: selectedPartidaId,
                            decoration: const InputDecoration(labelText: 'Partida Presupuestaria (Opcional)'),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('Ninguna')),
                              ...partidas.map((partida) => DropdownMenuItem<String>(value: partida.id, child: Text('${partida.nombre} (${partida.departamento?.nombre ?? 'N/A'})'))),
                            ],
                            onChanged: (value) => setState(() => selectedPartidaId = value),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(dialogContext).pop()),
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, loading, child) {
                return ElevatedButton(
                  onPressed: loading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      isLoading.value = true;
                      try {
                        await context.read<SolicitudCompraProvider>().addSolicitud({
                          'descripcion': descripcionController.text,
                          'costo_estimado': double.parse(costoEstimadoController.text),
                          'departamento_id': selectedDepartamentoId,
                          'partida_presupuestaria_id': selectedPartidaId,
                        });
                        isLoading.value = false;
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitud creada con éxito')));
                      } catch (e) {
                        isLoading.value = false;
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear solicitud: ${e.toString()}')));
                        }
                      }
                    }
                  },
                  child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
                );
              },
            ),
          ],
        );
      },
    );
  }
}