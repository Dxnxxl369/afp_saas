// lib/screens/proveedores/proveedores_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/proveedor.dart';
import '../../providers/proveedor_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/provider_state.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProveedorProvider>(context, listen: false);
      if (provider.loadingState == LoadingState.idle) {
        provider.fetchProveedores();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<AuthProvider>().hasPermission('manage_proveedor');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
      ),
      body: Consumer<ProveedorProvider>(
        builder: (context, provider, child) {
          if (provider.loadingState == LoadingState.loading && provider.proveedores.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.loadingState == LoadingState.error) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${provider.errorMessage}', textAlign: TextAlign.center),
            ));
          }
          if (provider.loadingState == LoadingState.success && provider.proveedores.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No hay proveedores para mostrar.'),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                     icon: const Icon(LucideIcons.refreshCw, size: 16),
                     label: const Text('Recargar'),
                     onPressed: () => provider.fetchProveedores(),
                  )
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchProveedores,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: provider.proveedores.length,
              itemBuilder: (context, index) {
                final proveedor = provider.proveedores[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(LucideIcons.truck, size: 20),
                    ),
                    title: Text(proveedor.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NIT: ${proveedor.nit}'),
                        if (proveedor.email != null && proveedor.email!.isNotEmpty) Text('Email: ${proveedor.email}'),
                        if (proveedor.telefono != null && proveedor.telefono!.isNotEmpty) Text('Teléfono: ${proveedor.telefono}'),
                      ],
                    ),
                    trailing: canManage
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.pencil),
                                tooltip: 'Editar',
                                onPressed: () {
                                  _showProveedorDialog(context, provider, proveedor: proveedor);
                                },
                              ),
                              IconButton(
                                icon: Icon(LucideIcons.trash2, color: Theme.of(context).colorScheme.error),
                                tooltip: 'Eliminar',
                                onPressed: () {
                                  _showDeleteConfirmDialog(context, provider, proveedor.id);
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
                _showProveedorDialog(context, Provider.of<ProveedorProvider>(context, listen: false));
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }

  void _showProveedorDialog(BuildContext context, ProveedorProvider provider, {Proveedor? proveedor}) {
    final isEditing = proveedor != null;
    final formKey = GlobalKey<FormState>();

    final nombreController = TextEditingController(text: proveedor?.nombre ?? '');
    final nitController = TextEditingController(text: proveedor?.nit ?? '');
    final emailController = TextEditingController(text: proveedor?.email ?? '');
    final telefonoController = TextEditingController(text: proveedor?.telefono ?? '');
    final paisController = TextEditingController(text: proveedor?.pais ?? '');
    final direccionController = TextEditingController(text: proveedor?.direccion ?? '');
    String estado = proveedor?.estado ?? 'activo';

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isLoading = ValueNotifier<bool>(false);
        
        return AlertDialog(
          title: Text(isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor'),
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
                    controller: nitController,
                    decoration: const InputDecoration(labelText: 'NIT'),
                    validator: (value) => (value == null || value.isEmpty) ? 'El NIT es requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email (Opcional)'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: telefonoController,
                    decoration: const InputDecoration(labelText: 'Teléfono (Opcional)'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: paisController,
                    decoration: const InputDecoration(labelText: 'País (Opcional)'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: direccionController,
                    decoration: const InputDecoration(labelText: 'Dirección (Opcional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: estado,
                    items: const [
                      DropdownMenuItem(value: 'activo', child: Text('Activo')),
                      DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                    ],
                    onChanged: (value) {
                      if (value != null) estado = value;
                    },
                    decoration: const InputDecoration(labelText: 'Estado'),
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
                        'nit': nitController.text,
                        'email': emailController.text.isEmpty ? null : emailController.text,
                        'telefono': telefonoController.text.isEmpty ? null : telefonoController.text,
                        'pais': paisController.text.isEmpty ? null : paisController.text,
                        'direccion': direccionController.text.isEmpty ? null : direccionController.text,
                        'estado': estado,
                      };

                      bool success;
                      if (isEditing) {
                        success = await provider.updateProveedor(proveedor.id, data);
                      } else {
                        success = await provider.createProveedor(data);
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

  void _showDeleteConfirmDialog(BuildContext context, ProveedorProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) {
        final isLoading = ValueNotifier<bool>(false);
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que quieres eliminar este proveedor?'),
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
                    bool success = await provider.deleteProveedor(id);
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
