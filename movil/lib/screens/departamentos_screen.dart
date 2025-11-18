// lib/screens/departamentos_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../models/departamento.dart';
import '../providers/departamento_provider.dart';
import '../providers/auth_provider.dart';

class DepartamentosScreen extends StatefulWidget {
  const DepartamentosScreen({super.key});

  @override
  State<DepartamentosScreen> createState() => _DepartamentosScreenState();
}

class _DepartamentosScreenState extends State<DepartamentosScreen> {
  
  @override
  void initState() {
    super.initState();
    // Cargar los datos la primera vez que esta pantalla se construye
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DepartamentoProvider>(context, listen: false);
      if (provider.loadingState == LoadingState.idle) {
        debugPrint("DepartamentosScreen: Fetching departamentos...");
        provider.fetchDepartamentos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Leer permisos
    final canManage = context.read<AuthProvider>().hasPermission('manage_departamento');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Departamentos'),
        // El AppBar ya está en HomeScreen, así que no necesitamos uno aquí
        // (A menos que quieras un AppBar *dentro* del body)
        // Esta pantalla se muestra *dentro* del body de HomeScreen,
        // así que el AppBar principal ya está.
        // Vamos a quitar este AppBar duplicado.
      ),
      // --- [CORRECCIÓN] No necesitamos un Scaffold si esto va en el body de HomeScreen ---
      // El Scaffold (con AppBar y FAB) debe estar en la pantalla *contenedora*.
      // `HomeScreen` ya tiene un Scaffold.
      // `DepartamentosScreen` solo debe devolver el contenido del body.
      body: Consumer<DepartamentoProvider>(
        builder: (context, provider, child) {
          if (provider.loadingState == LoadingState.loading && provider.departamentos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.loadingState == LoadingState.error) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${provider.errorMessage}', textAlign: TextAlign.center),
            ));
          }
          if (provider.loadingState == LoadingState.success && provider.departamentos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No hay departamentos para mostrar.'),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                     icon: const Icon(LucideIcons.refreshCw, size: 16),
                     label: const Text('Recargar'),
                     onPressed: () => provider.fetchDepartamentos(),
                  )
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchDepartamentos,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0), // Añadir padding
              itemCount: provider.departamentos.length,
              itemBuilder: (context, index) {
                final depto = provider.departamentos[index];
                return Card( // Usar Card para un mejor look
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(LucideIcons.building2, size: 20),
                    ),
                    title: Text(depto.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(depto.descripcion ?? 'Sin descripción'),
                    trailing: canManage
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.pencil),
                                tooltip: 'Editar',
                                onPressed: () {
                                  _showDepartamentoDialog(context, provider, departamento: depto);
                                },
                              ),
                              IconButton(
                                icon: Icon(LucideIcons.trash2, color: Theme.of(context).colorScheme.error),
                                tooltip: 'Eliminar',
                                onPressed: () {
                                  _showDeleteConfirmDialog(context, provider, depto.id);
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
                _showDepartamentoDialog(context, Provider.of<DepartamentoProvider>(context, listen: false));
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }

  // --- Diálogo para Crear/Editar ---
  void _showDepartamentoDialog(BuildContext context, DepartamentoProvider provider, {Departamento? departamento}) {
    final isEditing = departamento != null;
    final nombreController = TextEditingController(text: departamento?.nombre ?? '');
    final descController = TextEditingController(text: departamento?.descripcion ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        // Usar un 'ValueNotifier' para el estado de carga del botón
        final isLoading = ValueNotifier<bool>(false);
        
        return AlertDialog(
          title: Text(isEditing ? 'Editar Departamento' : 'Nuevo Departamento'),
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
            // Usar ValueListenableBuilder para el botón de guardar
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, loading, child) {
                return ElevatedButton(
                  onPressed: loading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      isLoading.value = true; // Deshabilitar botón
                      final nombre = nombreController.text;
                      final descripcion = descController.text.isNotEmpty ? descController.text : null;
                      bool success;
                      if (isEditing) {
                        success = await provider.updateDepartamento(departamento.id, nombre, descripcion);
                      } else {
                        success = await provider.createDepartamento(nombre, descripcion);
                      }
                      
                      isLoading.value = false; // Habilitar botón

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

  // --- Diálogo de Confirmación para Borrar ---
  void _showDeleteConfirmDialog(BuildContext context, DepartamentoProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) {
        final isLoading = ValueNotifier<bool>(false);
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que quieres eliminar este departamento?'),
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
                    bool success = await provider.deleteDepartamento(id);
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