// lib/screens/cargos/cargos_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/cargo.dart';
import '../../providers/cargos_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/provider_state.dart';

class CargosScreen extends StatefulWidget {
  const CargosScreen({super.key});

  @override
  State<CargosScreen> createState() => _CargosScreenState();
}

class _CargosScreenState extends State<CargosScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CargosProvider>(context, listen: false);
      if (provider.loadingState == LoadingState.idle) {
        provider.fetchCargos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<AuthProvider>().hasPermission('manage_cargo');

    return Scaffold(
      body: Consumer<CargosProvider>(
        builder: (context, provider, child) {
          if (provider.loadingState == LoadingState.loading && provider.cargos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.loadingState == LoadingState.error) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${provider.errorMessage}', textAlign: TextAlign.center),
            ));
          }
          if (provider.loadingState == LoadingState.success && provider.cargos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No hay cargos para mostrar.'),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                     icon: const Icon(LucideIcons.refreshCw, size: 16),
                     label: const Text('Recargar'),
                     onPressed: () => provider.fetchCargos(),
                  )
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchCargos,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: provider.cargos.length,
              itemBuilder: (context, index) {
                final cargo = provider.cargos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(LucideIcons.briefcase, size: 20),
                    ),
                    title: Text(cargo.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(cargo.descripcion ?? 'Sin descripción'),
                    trailing: canManage
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.pencil),
                                tooltip: 'Editar',
                                onPressed: () {
                                  _showCargoDialog(context, provider, cargo: cargo);
                                },
                              ),
                              IconButton(
                                icon: Icon(LucideIcons.trash2, color: Theme.of(context).colorScheme.error),
                                tooltip: 'Eliminar',
                                onPressed: () {
                                  _showDeleteConfirmDialog(context, provider, cargo.id);
                                },
                              ),
                            ],
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
              onPressed: () {
                _showCargoDialog(context, Provider.of<CargosProvider>(context, listen: false));
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }

  void _showCargoDialog(BuildContext context, CargosProvider provider, {Cargo? cargo}) {
    final isEditing = cargo != null;
    final nombreController = TextEditingController(text: cargo?.nombre ?? '');
    final descController = TextEditingController(text: cargo?.descripcion ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final isLoading = ValueNotifier<bool>(false);
        
        return AlertDialog(
          title: Text(isEditing ? 'Editar Cargo' : 'Nuevo Cargo'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => (value == null || value.isEmpty) ? 'El nombre es requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Descripción (Opcional)'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, loading, child) {
                return ElevatedButton(
                  onPressed: loading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      isLoading.value = true;
                      final nombre = nombreController.text;
                      final descripcion = descController.text.isNotEmpty ? descController.text : null;
                      bool success;
                      if (isEditing) {
                        success = await provider.updateCargo(cargo.id, nombre, descripcion);
                      } else {
                        success = await provider.createCargo(nombre, descripcion);
                      }
                      
                      isLoading.value = false;

                      if (context.mounted) {
                        if (success) {
                          Navigator.of(context).pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: Colors.red),
                          );
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

  void _showDeleteConfirmDialog(BuildContext context, CargosProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) {
        final isLoading = ValueNotifier<bool>(false);
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que quieres eliminar este cargo?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, loading, child) {
                return TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: loading ? null : () async {
                    isLoading.value = true;
                    bool success = await provider.deleteCargo(id);
                    isLoading.value = false;
                     if (context.mounted) {
                        Navigator.of(context).pop();
                         if (!success) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: Colors.red),
                            );
                         }
                     }
                  },
                  child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)) : const Text('Eliminar'),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
