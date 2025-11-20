// movil/lib/screens/roles/role_permissions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../providers/roles_provider.dart';
import '../../models/rol.dart';
import '../../models/permiso.dart';

class RolePermissionsScreen extends StatefulWidget {
  final Rol role;

  const RolePermissionsScreen({super.key, required this.role});

  @override
  State<RolePermissionsScreen> createState() => _RolePermissionsScreenState();
}

class _RolePermissionsScreenState extends State<RolePermissionsScreen> {
  final List<String> _selectedPermissionIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPermissionIds.addAll(widget.role.permisos.map((p) => p.id));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RolesProvider>(context, listen: false).fetchAllPermissions();
    });
  }

  Future<void> _savePermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<RolesProvider>(context, listen: false)
          .updateRolePermissions(widget.role.id, _selectedPermissionIds);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permisos del rol actualizados con éxito.')),
      );
      Navigator.of(context).pop(); // Go back to roles list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar permisos: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Permisos para ${widget.role.nombre}'),
        actions: [
          IconButton(
            icon: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(LucideIcons.save),
            onPressed: _isLoading ? null : _savePermissions,
            tooltip: 'Guardar Permisos',
          ),
        ],
      ),
      body: Consumer<RolesProvider>(
        builder: (context, rolesProvider, child) {
          if (rolesProvider.isLoading && rolesProvider.allPermissions.isEmpty) {
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

          if (rolesProvider.allPermissions.isEmpty) {
            return const Center(
              child: Text('No hay permisos disponibles.', style: TextStyle(fontSize: 16)),
            );
          }

          return ListView.builder(
            itemCount: rolesProvider.allPermissions.length,
            itemBuilder: (context, index) {
              final permiso = rolesProvider.allPermissions[index];
              return CheckboxListTile(
                title: Text(permiso.nombre),
                subtitle: Text(permiso.descripcion),
                value: _selectedPermissionIds.contains(permiso.id),
                onChanged: _isLoading
                    ? null
                    : (bool? newValue) {
                        setState(() {
                          if (newValue == true) {
                            _selectedPermissionIds.add(permiso.id);
                          } else {
                            _selectedPermissionIds.remove(permiso.id);
                          }
                        });
                      },
              );
            },
          );
        },
      ),
    );
  }
}
