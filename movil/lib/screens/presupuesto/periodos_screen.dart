// lib/screens/presupuesto/periodos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../providers/presupuesto_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/periodo_presupuestario.dart';
import 'periodo_form.dart';
import 'partidas_screen.dart';

class PeriodosScreen extends StatefulWidget {
  const PeriodosScreen({super.key});

  @override
  State<PeriodosScreen> createState() => _PeriodosScreenState();
}

class _PeriodosScreenState extends State<PeriodosScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar los datos iniciales cuando el widget se construye
    // Usamos addPostFrameCallback para asegurar que el context esté disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresupuestoProvider>().fetchPeriodos();
    });
  }

  void _showPeriodoForm({PeriodoPresupuestario? periodo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PeriodoForm(periodo: periodo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final canManage = authProvider.hasPermission('manage_presupuesto');

    return Scaffold(
      body: Consumer<PresupuestoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingPeriodos) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorPeriodos != null) {
            return Center(
              child: Text('Error: ${provider.errorPeriodos}'),
            );
          }

          if (provider.periodos.isEmpty) {
            return const Center(
              child: Text('No hay períodos presupuestarios.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchPeriodos(),
            child: ListView.builder(
              itemCount: provider.periodos.length,
              itemBuilder: (context, index) {
                final periodo = provider.periodos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(LucideIcons.calendarDays, color: _getStatusColor(periodo.estado)),
                    title: Text(periodo.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${periodo.fechaInicio.toLocal().toString().split(' ')[0]} - ${periodo.fechaFin.toLocal().toString().split(' ')[0]}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(periodo.estado, style: TextStyle(color: _getStatusColor(periodo.estado), fontWeight: FontWeight.bold)),
                        if (canManage)
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showPeriodoForm(periodo: periodo);
                              } else if (value == 'delete') {
                                _confirmDelete(context, periodo);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Editar')),
                              const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                            ],
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PartidasScreen(periodo: periodo)),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => _showPeriodoForm(),
              child: const Icon(Icons.add),
              tooltip: 'Nuevo Período',
            )
          : null,
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'ACTIVO':
        return Colors.green;
      case 'PLANIFICACION':
        return Colors.orange;
      case 'CERRADO':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  void _confirmDelete(BuildContext context, PeriodoPresupuestario periodo) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar el período "${periodo.nombre}"? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () {
                context.read<PresupuestoProvider>().deletePeriodo(periodo.id).catchError((e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
                  );
                });
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
