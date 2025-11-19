// lib/screens/empleados/empleados_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/empleado_provider.dart';
import '../../providers/provider_state.dart';

class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EmpleadoProvider>(context, listen: false);
      if (provider.loadingState == LoadingState.idle) {
        provider.fetchEmpleados();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<EmpleadoProvider>(
        builder: (context, provider, child) {
          if (provider.loadingState == LoadingState.loading && provider.empleados.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.loadingState == LoadingState.error) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${provider.errorMessage}', textAlign: TextAlign.center),
            ));
          }
          if (provider.loadingState == LoadingState.success && provider.empleados.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No hay empleados para mostrar.'),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                     icon: const Icon(LucideIcons.refreshCw, size: 16),
                     label: const Text('Recargar'),
                     onPressed: () => provider.fetchEmpleados(),
                  )
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchEmpleados,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: provider.empleados.length,
              itemBuilder: (context, index) {
                final empleado = provider.empleados[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondary.withAlpha(26),
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                      child: const Icon(LucideIcons.user, size: 20),
                    ),
                    title: Text(empleado.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(empleado.email),
                        if (empleado.cargoNombre != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(empleado.cargoNombre!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          ),
                      ],
                    ),
                    isThreeLine: empleado.cargoNombre != null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
