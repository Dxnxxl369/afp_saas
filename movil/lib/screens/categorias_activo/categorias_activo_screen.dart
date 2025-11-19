// lib/screens/categorias_activo/categorias_activo_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/categoria_activo.dart';
import '../../providers/categoria_activo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/provider_state.dart';

class CategoriasActivoScreen extends StatefulWidget {
  const CategoriasActivoScreen({super.key});

  @override
  State<CategoriasActivoScreen> createState() => _CategoriasActivoScreenState();
}

class _CategoriasActivoScreenState extends State<CategoriasActivoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CategoriaActivoProvider>(context, listen: false);
      if (provider.loadingState == LoadingState.idle) {
        provider.fetchCategoriasActivo();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<AuthProvider>().hasPermission('manage_categoriaactivo');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías de Activo'),
      ),
      body: Consumer<CategoriaActivoProvider>(
        builder: (context, provider, child) {
          if (provider.loadingState == LoadingState.loading && provider.categorias.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.loadingState == LoadingState.error) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${provider.errorMessage}', textAlign: TextAlign.center),
            ));
          }
          if (provider.loadingState == LoadingState.success && provider.categorias.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No hay categorías de activo para mostrar.'),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                     icon: const Icon(LucideIcons.refreshCw, size: 16),
                     label: const Text('Recargar'),
                     onPressed: () => provider.fetchCategoriasActivo(),
                  )
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchCategoriasActivo,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: provider.categorias.length,
              itemBuilder: (context, index) {
                final categoria = provider.categorias[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(LucideIcons.tag, size: 20),
                    ),
                    title: Text(categoria.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: categoria.descripcion != null && categoria.descripcion!.isNotEmpty
                        ? Text(categoria.descripcion!)
                        : null,
                    trailing: canManage
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.pencil),
                                tooltip: 'Editar',
                                onPressed: () {
                                  _showCategoriaActivoDialog(context, provider, categoria: categoria);
                                },
                              ),
                              IconButton(
                                icon: Icon(LucideIcons.trash2, color: Theme.of(context).colorScheme.error),
                                tooltip: 'Eliminar',
                                onPressed: () {
                                  _showDeleteConfirmDialog(context, provider, categoria.id);
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
                _showCategoriaActivoDialog(context, Provider.of<CategoriaActivoProvider>(context, listen: false));
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }

  void _showCategoriaActivoDialog(BuildContext context, CategoriaActivoProvider provider, {CategoriaActivo? categoria}) {
    final isEditing = categoria != null;
    final formKey = GlobalKey<FormState>();

    final nombreController = TextEditingController(text: categoria?.nombre ?? '');
    final descripcionController = TextEditingController(text: categoria?.descripcion ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isLoading = ValueNotifier<bool>(false);
        
        return AlertDialog(
          title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
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
                    controller: descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripción (Opcional)'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, loading, child) {
                return ElevatedButton(
                  onPressed: loading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      isLoading.value = true;
                      
                      final data = {
                        'nombre': nombreController.text,
                        'descripcion': descripcionController.text.isEmpty ? null : descripcionController.text,
                      };

                      bool success;
                      if (isEditing) {
                        success = await provider.updateCategoriaActivo(categoria.id, data);
                      } else {
                        success = await provider.createCategoriaActivo(data);
                      }
                      
                      isLoading.value = false;

                      if (context.mounted) {
                        if (success) {
                          Navigator.of(dialogContext).pop();
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

  void _showDeleteConfirmDialog(BuildContext context, CategoriaActivoProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) {
        final isLoading = ValueNotifier<bool>(false);
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que quieres eliminar esta categoría de activo?'),
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
                    bool success = await provider.deleteCategoriaActivo(id);
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
