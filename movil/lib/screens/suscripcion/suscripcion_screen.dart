// lib/screens/suscripcion/suscripcion_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/suscripcion_provider.dart';
import '../../providers/provider_state.dart';

class SuscripcionScreen extends StatefulWidget {
  const SuscripcionScreen({super.key});

  @override
  State<SuscripcionScreen> createState() => _SuscripcionScreenState();
}

class _SuscripcionScreenState extends State<SuscripcionScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SuscripcionProvider>(context, listen: false);
      if (provider.loadingState == LoadingState.idle) {
        provider.fetchSuscripcion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SuscripcionProvider>(
        builder: (context, provider, child) {
          if (provider.loadingState == LoadingState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.loadingState == LoadingState.error) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${provider.errorMessage}', textAlign: TextAlign.center),
            ));
          }
          if (provider.suscripcion == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No se encontró información de la suscripción.'),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                     icon: const Icon(LucideIcons.refreshCw, size: 16),
                     label: const Text('Recargar'),
                     onPressed: () => provider.fetchSuscripcion(),
                  )
                ],
              ),
            );
          }

          final suscripcion = provider.suscripcion!;
          final dateFormat = DateFormat('dd/MM/yyyy');

          return RefreshIndicator(
            onRefresh: provider.fetchSuscripcion,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(
                              suscripcion.planDisplay,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text(suscripcion.estadoDisplay),
                              backgroundColor: suscripcion.estado == 'activa' ? Colors.green.shade100 : Colors.red.shade100,
                              labelStyle: TextStyle(color: suscripcion.estado == 'activa' ? Colors.green.shade800 : Colors.red.shade800),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 32),
                      _buildInfoRow(context, LucideIcons.calendar, 'Fecha de Inicio', dateFormat.format(suscripcion.fechaInicio)),
                      _buildInfoRow(context, LucideIcons.calendarOff, 'Fecha de Fin', dateFormat.format(suscripcion.fechaFin)),
                      const Divider(height: 32),
                      _buildInfoRow(context, LucideIcons.users, 'Límite de Usuarios', suscripcion.maxUsuarios.toString()),
                      _buildInfoRow(context, LucideIcons.archive, 'Límite de Activos', suscripcion.maxActivos.toString()),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 16),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }
}
