// lib/screens/ordenes_compra/ordenes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/orden_compra_provider.dart';
import '../../providers/auth_provider.dart';
import 'create_orden_compra_screen.dart';
import 'recibir_orden_screen.dart';

class OrdenesScreen extends StatefulWidget {
  const OrdenesScreen({super.key});

  @override
  State<OrdenesScreen> createState() => _OrdenesScreenState();
}

class _OrdenesScreenState extends State<OrdenesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Usar listen:false en initState
      Provider.of<OrdenCompraProvider>(context, listen: false).fetchOrdenes();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usar listen:false aquí si solo se necesita para el check de permiso inicial
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canReceive = authProvider.hasPermission('receive_orden_compra');
    final canManage = authProvider.hasPermission('manage_orden_compra');

    return Scaffold(
      body: Consumer<OrdenCompraProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.ordenes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.ordenes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error al cargar las órdenes: ${provider.error}'),
              ),
            );
          }

          if (provider.ordenes.isEmpty) {
            return const Center(child: Text('No hay órdenes de compra.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchOrdenes(),
            child: ListView.builder(
              itemCount: provider.ordenes.length,
              itemBuilder: (context, index) {
                final orden = provider.ordenes[index];
                final isReceivable = orden.estado == 'ENVIADA' || orden.estado == 'GENERADA';

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
                              orden.proveedorNombre,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Chip(
                              label: Text(orden.estado),
                              backgroundColor: _getStatusColor(orden.estado).withOpacity(0.2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          orden.solicitudDescripcion,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Precio Final: \$${orden.precioFinal.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy').format(orden.fechaOrden)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (isReceivable && canReceive)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => RecibirOrdenScreen(orden: orden),
                                    ),
                                  );
                                },
                                child: const Text('Recibir Activo'),
                              ),
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
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Crear Orden'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateOrdenCompraScreen(),
                  ),
                );
              },
            )
          : null,
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'COMPLETADA':
        return Colors.green;
      case 'ENVIADA':
        return Colors.blue;
      case 'GENERADA':
        return Colors.orange;
      case 'CANCELADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
