// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  final String selectedPageKey;
  final Function(String) onNavigate;

  const AppDrawer({
    super.key,
    required this.selectedPageKey,
    required this.onNavigate,
  });

  // Helper para construir los items del menú
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String pageKey,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title),
      selected: isSelected, // Marca el ítem como seleccionado
      // Colores cuando está seleccionado (usa los colores del tema)
      selectedTileColor: Theme.of(context).colorScheme.primary.withAlpha(26),
      selectedColor: Theme.of(context).colorScheme.primary,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos 'context.read' para obtener el provider solo para leer permisos
    // Asumimos que los permisos no cambian durante la sesión
    final auth = context.read<AuthProvider>();

    return Drawer(
      child: Column(
        children: <Widget>[
          // --- Cabecera del Drawer ---
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary, // Color de acento
            ),
            child: Center(
              child: Text(
                'ActFijo App',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary, // Texto sobre el acento
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // --- Lista de Módulos (con chequeo de permisos) ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                // Dashboard (asumimos que todos pueden ver)
                _buildNavItem(
                  context: context,
                  icon: LucideIcons.layoutGrid,
                  title: 'Dashboard',
                  pageKey: 'dashboard',
                  isSelected: selectedPageKey == 'dashboard',
                  onTap: () => onNavigate('dashboard'),
                ),

                // Módulo Departamentos
                if (auth.hasPermission('view_departamento'))
                  _buildNavItem(
                    context: context,
                    icon: LucideIcons.building2,
                    title: 'Departamentos',
                    pageKey: 'departamentos',
                    isSelected: selectedPageKey == 'departamentos',
                    onTap: () => onNavigate('departamentos'),
                  ),
                
                // Módulo Empleados
                if (auth.hasPermission('view_empleado'))
                  _buildNavItem(
                    context: context,
                    icon: LucideIcons.users,
                    title: 'Empleados',
                    pageKey: 'empleados',
                    isSelected: selectedPageKey == 'empleados',
                    onTap: () => onNavigate('empleados'),
                  ),

                // Módulo Activos Fijos
                if (auth.hasPermission('view_activofijo'))
                  _buildNavItem(
                    context: context,
                    icon: LucideIcons.box,
                    title: 'Activos Fijos',
                    pageKey: 'activos_fijos',
                    isSelected: selectedPageKey == 'activos_fijos',
                    onTap: () => onNavigate('activos_fijos'),
                  ),
                
                // Módulo Mantenimientos
                if (auth.hasPermission('view_mantenimiento'))
                  _buildNavItem(
                    context: context,
                    icon: LucideIcons.wrench,
                    title: 'Mantenimientos',
                    pageKey: 'mantenimientos',
                    isSelected: selectedPageKey == 'mantenimientos',
                    onTap: () => onNavigate('mantenimientos'),
                  ),
                
                // ... (Añadir Cargos, Roles, Presupuestos, etc. con sus permisos) ...
                
              ],
            ),
          ),
          
          // --- Configuración y Logout (fijos al final) ---
          const Divider(height: 1), // Línea divisoria
          _buildNavItem(
            context: context,
            icon: LucideIcons.settings,
            title: 'Configuración',
            pageKey: 'settings',
            isSelected: false, 
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.logOut, color: Colors.red),
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
    );
  }
}