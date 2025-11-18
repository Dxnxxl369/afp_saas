// lib/screens/activos/activos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../providers/activo_fijo_provider.dart';
import '../../providers/provider_state.dart';

class ActivosScreen extends StatefulWidget {
  const ActivosScreen({super.key});

  @override
  State<ActivosScreen> createState() => _ActivosScreenState();
}

class _ActivosScreenState extends State<ActivosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ActivoFijoProvider>();
      if (provider.loadingState == LoadingState.idle) {
        provider.fetchActivos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ActivoFijoProvider>(
        builder: (context, provider, child) {
          if (provider.loadingState == LoadingState.loading && provider.activos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.loadingState == LoadingState.error) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          if (provider.loadingState == LoadingState.success && provider.activos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No hay activos fijos para mostrar.'),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                     icon: const Icon(LucideIcons.refreshCw, size: 16),
                     label: const Text('Recargar'),
                     onPressed: () => provider.fetchActivos(),
                  )
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchActivos(),
            child: ListView.builder(
              itemCount: provider.activos.length,
              itemBuilder: (context, index) {
                final activo = provider.activos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activo.fotoActivoUrl != null)
                        CachedNetworkImage(
                          imageUrl: activo.fotoActivoUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error, size: 40),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activo.nombre,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Chip(
                              label: Text(activo.estadoNombre),
                              backgroundColor: Colors.blue.withOpacity(0.2),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Código: ${activo.codigoInterno}'),
                                Text('\$${activo.valorActual.toStringAsFixed(2)}'),
                              ],
                            ),
                            if (activo.departamentoNombre != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('Dpto: ${activo.departamentoNombre}'),
                              ),
                          ],
                        ),
                      ),
                    ],
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
