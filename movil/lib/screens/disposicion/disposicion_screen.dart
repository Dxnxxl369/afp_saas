// lib/screens/disposicion/disposicion_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/disposicion.dart';
import '../../models/activo_fijo.dart';
import '../../providers/disposicion_provider.dart';
import '../../providers/activo_fijo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/provider_state.dart';

class DisposicionScreen extends StatefulWidget {
  const DisposicionScreen({super.key});

  @override
  State<DisposicionScreen> createState() => _DisposicionScreenState();
}

class _DisposicionScreenState extends State<DisposicionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final disposicionProvider = Provider.of<DisposicionProvider>(context, listen: false);
      if (disposicionProvider.loadingState == LoadingState.idle) {
        disposicionProvider.fetchDisposiciones();
      }
      // También precargamos los activos para el formulario
      final activoProvider = Provider.of<ActivoFijoProvider>(context, listen: false);
      if (activoProvider.loadingState == LoadingState.idle) {
        activoProvider.fetchActivos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<AuthProvider>().hasPermission('manage_disposicion');

    return Scaffold(
      body: Consumer<DisposicionProvider>(
        builder: (context, provider, child) {
          if (provider.loadingState == LoadingState.loading && provider.disposiciones.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.loadingState == LoadingState.error) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }
          if (provider.loadingState == LoadingState.success && provider.disposiciones.isEmpty) {
            return Center(child: Text('No hay disposiciones registradas.'));
          }

          return RefreshIndicator(
            onRefresh: provider.fetchDisposiciones,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: provider.disposiciones.length,
              itemBuilder: (context, index) {
                final disposicion = provider.disposiciones[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.error.withAlpha(26),
                      foregroundColor: Theme.of(context).colorScheme.error,
                      child: const Icon(LucideIcons.archive, size: 20),
                    ),
                    title: Text(disposicion.activo.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${disposicion.tipoDisposicionDisplay}\n${DateFormat.yMMMd('es_ES').format(disposicion.fechaDisposicion)}'),
                    isThreeLine: true,
                    trailing: canManage
                        ? IconButton(
                            icon: Icon(LucideIcons.trash2, color: Theme.of(context).colorScheme.error),
                            tooltip: 'Eliminar',
                            onPressed: () => _showDeleteConfirmDialog(context, provider, disposicion.id),
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => _showDisposicionDialog(context, Provider.of<DisposicionProvider>(context, listen: false)),
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }

  void _showDisposicionDialog(BuildContext context, DisposicionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _DisposicionFormDialog(provider: provider),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, DisposicionProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este registro de disposición? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
            onPressed: () async {
              bool success = await provider.deleteDisposicion(id);
              if (context.mounted) {
                Navigator.of(context).pop();
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DisposicionFormDialog extends StatefulWidget {
  final DisposicionProvider provider;

  const _DisposicionFormDialog({required this.provider});

  @override
  State<_DisposicionFormDialog> createState() => _DisposicionFormDialogState();
}

class _DisposicionFormDialogState extends State<_DisposicionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedActivoId;
  String _tipoDisposicion = 'BAJA';
  DateTime _fechaDisposicion = DateTime.now();
  final _valorVentaController = TextEditingController();
  final _razonController = TextEditingController();

  final List<Map<String, String>> _tiposDisposicion = [
    {'value': 'VENTA', 'label': 'Venta'},
    {'value': 'BAJA', 'label': 'Baja por Obsolescencia/Daño'},
    {'value': 'DONACION', 'label': 'Donación'},
    {'value': 'ROBO', 'label': 'Robo/Pérdida'},
    {'value': 'OTRO', 'label': 'Otro'},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Nueva Disposición'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<ActivoFijoProvider>(
                builder: (context, activoProvider, child) {
                  if (activoProvider.loadingState == LoadingState.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Filtramos para mostrar solo activos que no están dados de baja
                  final activosDisponibles = activoProvider.activos.where((a) => a.estado.nombre != 'DADO_DE_BAJA').toList();

                  return DropdownButtonFormField<String>(
                    value: _selectedActivoId,
                    decoration: const InputDecoration(labelText: 'Activo a dar de baja'),
                    items: activosDisponibles.map((ActivoFijo activo) {
                      return DropdownMenuItem<String>(
                        value: activo.id,
                        child: Text(activo.nombre),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedActivoId = value),
                    validator: (value) => value == null ? 'Seleccione un activo' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipoDisposicion,
                decoration: const InputDecoration(labelText: 'Tipo de Disposición'),
                items: _tiposDisposicion.map((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo['value'],
                    child: Text(tipo['label']!),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _tipoDisposicion = value!),
              ),
              if (_tipoDisposicion == 'VENTA') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valorVentaController,
                  decoration: const InputDecoration(labelText: 'Valor de Venta (Opcional)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _razonController,
                decoration: const InputDecoration(labelText: 'Razón / Motivo (Opcional)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
        ElevatedButton(
          child: const Text('Guardar'),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final data = {
                'activo_id': _selectedActivoId,
                'tipo_disposicion': _tipoDisposicion,
                'fecha_disposicion': DateFormat('yyyy-MM-dd').format(_fechaDisposicion),
                'valor_venta': _valorVentaController.text.isNotEmpty ? _valorVentaController.text : null,
                'razon': _razonController.text.isNotEmpty ? _razonController.text : null,
              };

              bool success = await widget.provider.createDisposicion(data);
              if (context.mounted) {
                if (success) {
                  Navigator.of(context).pop();
                  // Refrescar lista de activos también
                  Provider.of<ActivoFijoProvider>(context, listen: false).fetchActivos();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${widget.provider.errorMessage}'), backgroundColor: Colors.red),
                  );
                }
              }
            }
          },
        ),
      ],
    );
  }
}
