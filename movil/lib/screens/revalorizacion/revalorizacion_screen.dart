// lib/screens/revalorizacion/revalorizacion_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/activo_fijo.dart';
import '../../providers/activo_fijo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/revalorizacion_provider.dart';
import '../../providers/provider_state.dart';

class RevalorizacionScreen extends StatefulWidget {
  const RevalorizacionScreen({super.key});

  @override
  State<RevalorizacionScreen> createState() => _RevalorizacionScreenState();
}

class _RevalorizacionScreenState extends State<RevalorizacionScreen> {
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
      Provider.of<RevalorizacionProvider>(context, listen: false).fetchRevalorizaciones(activoId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<AuthProvider>().hasPermission('manage_revalorizacion');
    final activoProvider = context.watch<ActivoFijoProvider>();
    final activosDisponibles = activoProvider.activos.where((a) => a.estado.nombre != 'DADO_DE_BAJA').toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        decoration: const InputDecoration(labelText: 'Activo a Revalorizar', border: OutlineInputBorder()),
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
                        _RevalorizacionForm(activoId: _selectedActivoId!),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Historial de Revalorizaciones', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Consumer<RevalorizacionProvider>(
                      builder: (context, provider, _) {
                        if (_selectedActivoId == null) return const Center(child: Text('Seleccione un activo para ver su historial.'));
                        if (provider.loadingState == LoadingState.loading) return const Center(child: CircularProgressIndicator());
                        if (provider.historial.isEmpty) return const Center(child: Text('Este activo no tiene revalorizaciones.'));
                        
                        return ListView.builder(
                          itemCount: provider.historial.length,
                          itemBuilder: (context, index) {
                            final h = provider.historial[index];
                            final valorAnterior = double.tryParse(h.valorAnterior) ?? 0.0;
                            final valorNuevo = double.tryParse(h.valorNuevo) ?? 0.0;
                            final isIncrease = valorNuevo >= valorAnterior;
                            final color = isIncrease ? Colors.green : Colors.red;

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
                                        Text(isIncrease ? 'Revalorización' : 'Deterioro', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
                                      ],
                                    ),
                                    const Divider(),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Valor Anterior'), Text(NumberFormat.currency(locale: 'es_BO', symbol: '').format(valorAnterior))]),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(isIncrease ? 'Aumento' : 'Disminución'), Text('${isIncrease ? '+' : '-'} ${NumberFormat.currency(locale: 'es_BO', symbol: '').format((valorNuevo - valorAnterior).abs())}', style: TextStyle(color: color))]),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Valor Nuevo', style: TextStyle(fontWeight: FontWeight.bold)), Text(NumberFormat.currency(locale: 'es_BO', symbol: '').format(valorNuevo), style: const TextStyle(fontWeight: FontWeight.bold))]),
                                    if (h.notas != null && h.notas!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('Nota: ${h.notas}', style: Theme.of(context).textTheme.bodySmall)),
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

class _RevalorizacionForm extends StatefulWidget {
  final String activoId;
  const _RevalorizacionForm({required this.activoId});

  @override
  State<_RevalorizacionForm> createState() => __RevalorizacionFormState();
}

class __RevalorizacionFormState extends State<_RevalorizacionForm> {
  String _revalType = 'factor';
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'value': TextEditingController(),
    'notas': TextEditingController(),
  };

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ejecutar Revalorización', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _revalType,
            decoration: const InputDecoration(labelText: 'Método de Cálculo', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'factor', child: Text('Por Factor')),
              DropdownMenuItem(value: 'fijo', child: Text('A Monto Fijo')),
              DropdownMenuItem(value: 'porcentual', child: Text('Por Porcentaje')),
            ],
            onChanged: (value) => setState(() => _revalType = value!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controllers['value'],
            decoration: InputDecoration(labelText: _getLabelForValue(), border: const OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => v!.isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controllers['notas'],
            decoration: const InputDecoration(labelText: 'Notas (Opcional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.trendingUp),
            label: const Text('Revalorizar Activo'),
            onPressed: _handleEjecutar,
          )
        ],
      ),
    );
  }
  
  String _getLabelForValue() {
    switch (_revalType) {
      case 'factor': return 'Factor a Aplicar (Ej: 1.05)';
      case 'fijo': return 'Nuevo Valor Fijo (Bs.)';
      case 'porcentual': return 'Porcentaje de Aumento/Disminución (Ej: 5 o -10)';
      default: return 'Valor';
    }
  }

  void _handleEjecutar() async {
    if (!_formKey.currentState!.validate()) return;
    
    final provider = context.read<RevalorizacionProvider>();
    final activoProvider = context.read<ActivoFijoProvider>();

    final data = {
      'activo_id': widget.activoId,
      'reval_type': _revalType,
      'value': _controllers['value']!.text,
      'notas': _controllers['notas']!.text,
    };

    final success = await provider.ejecutarRevalorizacion(data);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revalorización ejecutada con éxito'), backgroundColor: Colors.green));
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