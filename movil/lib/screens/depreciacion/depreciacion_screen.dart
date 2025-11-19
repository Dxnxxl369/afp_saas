// lib/screens/depreciacion/depreciacion_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/activo_fijo.dart';
import '../../providers/activo_fijo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/depreciacion_provider.dart';
import '../../providers/provider_state.dart';

class DepreciacionScreen extends StatefulWidget {
  const DepreciacionScreen({super.key});

  @override
  State<DepreciacionScreen> createState() => _DepreciacionScreenState();
}

class _DepreciacionScreenState extends State<DepreciacionScreen> {
  String? _selectedActivoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activoProvider = Provider.of<ActivoFijoProvider>(context, listen: false);
      if (activoProvider.loadingState != LoadingState.loading) {
        activoProvider.fetchActivos();
      }
    });
  }

  void _onActivoChanged(String? activoId) {
    setState(() {
      _selectedActivoId = activoId;
    });
    if (activoId != null && activoId.isNotEmpty) {
      Provider.of<DepreciacionProvider>(context, listen: false).fetchDepreciaciones(activoId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<AuthProvider>().hasPermission('manage_depreciacion');
    final activoProvider = context.watch<ActivoFijoProvider>();

    final activosDisponibles = activoProvider.activos.where((a) => a.valorActual > 0 && a.estado.nombre != 'DADO_DE_BAJA').toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna Izquierda: Formulario
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seleccionar Activo', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    if (activoProvider.loadingState == LoadingState.loading)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedActivoId,
                        decoration: const InputDecoration(labelText: 'Activo a Depreciar', border: OutlineInputBorder()),
                        items: activosDisponibles.map((ActivoFijo activo) {
                          return DropdownMenuItem<String>(
                            value: activo.id,
                            child: Text(activo.nombre),
                          );
                        }).toList(),
                        onChanged: _onActivoChanged,
                      ),
                    
                    if (_selectedActivoId != null) ...[
                      const SizedBox(height: 24),
                      Consumer<ActivoFijoProvider>(
                        builder: (context, provider, _) {
                          final activo = provider.activos.firstWhere((a) => a.id == _selectedActivoId);
                          return Card(
                            child: ListTile(
                              title: const Text('Valor Actual'),
                              trailing: Text(
                                NumberFormat.currency(locale: 'es_BO', symbol: 'Bs. ').format(activo.valorActual),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      if (canManage)
                        _DepreciacionForm(activoId: _selectedActivoId!),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Columna Derecha: Historial
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Historial de Depreciaciones', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Consumer<DepreciacionProvider>(
                      builder: (context, provider, _) {
                        if (_selectedActivoId == null) {
                          return const Center(child: Text('Seleccione un activo para ver su historial.'));
                        }
                        if (provider.loadingState == LoadingState.loading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (provider.historial.isEmpty) {
                          return const Center(child: Text('Este activo no tiene depreciaciones.'));
                        }
                        return ListView.builder(
                          itemCount: provider.historial.length,
                          itemBuilder: (context, index) {
                            final h = provider.historial[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(DateFormat.yMMMd('es_ES').format(h.fecha), style: Theme.of(context).textTheme.bodySmall),
                                        Text(h.depreciationTypeDisplay, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Valor Anterior'),
                                        Text(NumberFormat.currency(locale: 'es_BO', symbol: '').format(double.parse(h.valorAnterior))),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Monto Depreciado'),
                                        Text('- ${NumberFormat.currency(locale: 'es_BO', symbol: '').format(double.parse(h.montoDepreciado))}', style: const TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Valor Nuevo', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(NumberFormat.currency(locale: 'es_BO', symbol: '').format(double.parse(h.valorNuevo)), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    if (h.notas != null && h.notas!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text('Nota: ${h.notas}', style: Theme.of(context).textTheme.bodySmall),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _DepreciacionForm extends StatefulWidget {
  final String activoId;
  const _DepreciacionForm({required this.activoId});

  @override
  State<_DepreciacionForm> createState() => __DepreciacionFormState();
}

class __DepreciacionFormState extends State<_DepreciacionForm> {
  String _depreciationType = 'STRAIGHT_LINE';
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'monto': TextEditingController(),
    'valor_residual': TextEditingController(),
    'tasa_depreciacion': TextEditingController(),
    'total_unidades_estimadas': TextEditingController(),
    'unidades_producidas': TextEditingController(),
    'notas': TextEditingController(),
  };

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ejecutar Depreciación', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _depreciationType,
            decoration: const InputDecoration(labelText: 'Método de Cálculo', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'STRAIGHT_LINE', child: Text('Línea Recta')),
              DropdownMenuItem(value: 'MANUAL', child: Text('Monto Manual')),
              DropdownMenuItem(value: 'DECLINING_BALANCE', child: Text('Saldo Decreciente')),
              DropdownMenuItem(value: 'UNITS_OF_PRODUCTION', child: Text('Unidades de Producción')),
            ],
            onChanged: (value) => setState(() => _depreciationType = value!),
          ),
          const SizedBox(height: 16),
          ..._buildDynamicFields(),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controllers['notas'],
            decoration: const InputDecoration(labelText: 'Notas (Opcional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.trendingDown),
            label: const Text('Depreciar Activo'),
            onPressed: _handleEjecutar,
          )
        ],
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    switch (_depreciationType) {
      case 'MANUAL':
        return [TextFormField(controller: _controllers['monto'], decoration: const InputDecoration(labelText: 'Monto a Depreciar'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null)];
      case 'STRAIGHT_LINE':
        return [TextFormField(controller: _controllers['valor_residual'], decoration: const InputDecoration(labelText: 'Valor Residual'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null)];
      case 'DECLINING_BALANCE':
        return [TextFormField(controller: _controllers['tasa_depreciacion'], decoration: const InputDecoration(labelText: 'Tasa (Ej: 0.2 para 20%)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null)];
      case 'UNITS_OF_PRODUCTION':
        return [
          TextFormField(controller: _controllers['total_unidades_estimadas'], decoration: const InputDecoration(labelText: 'Total Unidades Estimadas'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _controllers['unidades_producidas'], decoration: const InputDecoration(labelText: 'Unidades Producidas'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
        ];
      default:
        return [];
    }
  }

  void _handleEjecutar() async {
    if (!_formKey.currentState!.validate()) return;
    
    final provider = context.read<DepreciacionProvider>();
    final activoProvider = context.read<ActivoFijoProvider>();

    final data = {
      'activo_id': widget.activoId,
      'depreciation_type': _depreciationType,
      'notas': _controllers['notas']!.text,
    };

    _controllers.forEach((key, controller) {
      if (key != 'notas' && controller.text.isNotEmpty) {
        data[key] = controller.text;
      }
    });

    final success = await provider.ejecutarDepreciacion(data);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Depreciación ejecutada con éxito'), backgroundColor: Colors.green));
        // Refresh asset list to show updated value
        activoProvider.fetchActivos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}
