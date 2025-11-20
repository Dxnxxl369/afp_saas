// movil/lib/screens/roles/roles_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../providers/roles_provider.dart';
import '../../models/rol.dart';
import 'role_form_screen.dart';
import 'role_permissions_screen.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RolesProvider>(context, listen: false).fetchRoles();
    });
  }

  Future<void> _refreshRoles(BuildContext context) async {
    await Provider.of<RolesProvider>(context, listen: false).fetchRoles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Roles'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCcw),
            onPressed: () => _refreshRoles(context),
          ),
        ],
      ),
      body: Consumer<RolesProvider>(
        builder: (context, rolesProvider, child) {
          if (rolesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (rolesProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${rolesProvider.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (rolesProvider.roles.isEmpty) {
            return const Center(
              child: Text('No hay roles registrados.', style: TextStyle(fontSize: 16)),
            );
          }

          return ListView.builder(
            itemCount: rolesProvider.roles.length,
            itemBuilder: (context, index) {
              final rol = rolesProvider.roles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(rol.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('ID: ${rol.id.substring(0, 8)}...'), // Muestra un ID corto
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.shieldCheck, size: 20),
                        tooltip: 'Administrar Permisos',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => RolePermissionsScreen(role: rol),
                            ),
                          ).then((_) => _refreshRoles(context)); // Refresh roles after returning
                        },
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.pencil, size: 20),
                        tooltip: 'Editar Rol',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => RoleFormScreen(role: rol),
                            ),
                          ).then((_) => _refreshRoles(context)); // Refresh roles after returning
                        },
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.red),
                        tooltip: 'Eliminar Rol',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirmar Eliminación'),
                              content: Text('¿Está seguro de que desea eliminar el rol "${rol.nombre}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await rolesProvider.deleteRole(rol.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Rol eliminado con éxito.')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al eliminar rol: ${e.toString()}')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const RoleFormScreen(), // Para crear nuevo rol
            ),
          ).then((_) => _refreshRoles(context)); // Refresh roles after returning
        },
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}
