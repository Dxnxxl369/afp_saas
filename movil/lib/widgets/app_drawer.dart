// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/auth_provider.dart';
import '../utils/helpers.dart'; // Para getInitials

class AppDrawer extends StatelessWidget {
  final String selectedPageKey;
  final Function(String) onNavigate;

  const AppDrawer({
    super.key,
    required this.selectedPageKey,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    // --- Construcción dinámica de items del menú ---
    List<Widget> menuItems = [];

    // 1. Dashboard (siempre visible para usuarios logueados)
    menuItems.add(_buildDrawerItem(
      context: context,
      icon: LucideIcons.layoutDashboard,
      title: 'Dashboard',
      pageKey: 'dashboard',
    ));

    // 2. Módulos de Adquisición
    if (auth.hasPermission('view_solicitud_compra')) {
      menuItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.shoppingCart,
        title: 'Solicitudes de Compra',
        pageKey: 'solicitudes_compra',
      ));
    }
    if (auth.hasPermission('view_orden_compra')) {
      menuItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.fileText,
        title: 'Órdenes de Compra',
        pageKey: 'ordenes_compra',
      ));
    }

    // 3. Módulos Principales
    if (auth.hasPermission('view_activo')) {
       menuItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.scan,
        title: 'Activos Fijos',
        pageKey: 'activos_fijos',
      ));
    }
    if (auth.hasPermission('view_presupuesto')) {
       menuItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.piggyBank,
        title: 'Presupuestos',
        pageKey: 'presupuestos',
      ));
    }
    if (auth.hasPermission('view_mantenimiento')) {
       menuItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.wrench,
        title: 'Mantenimientos',
        pageKey: 'mantenimientos',
      ));
    }

    // 4. Módulos de Configuración
    List<Widget> settingsItems = [];
    if (auth.hasPermission('view_departamento')) {
      settingsItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.building2,
        title: 'Departamentos',
        pageKey: 'departamentos',
      ));
    }
    if (auth.hasPermission('view_empleado')) {
      settingsItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.users,
        title: 'Empleados',
        pageKey: 'empleados',
      ));
    }
    // ... agregar más items de configuración aquí (roles, permisos, etc.)

    if (settingsItems.isNotEmpty) {
      menuItems.add(const Divider());
      menuItems.add(const _DrawerHeaderTitle(title: 'Configuración'));
      menuItems.addAll(settingsItems);
    }
    
    return Drawer(
      child: Column(
        children: [
          // --- Cabecera del Drawer ---
          UserAccountsDrawerHeader(
            accountName: Text(
              user?.nombreCompleto ?? 'Usuario',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user?.email ?? 'email@example.com'),
            currentAccountPicture: (user?.fotoPerfilUrl != null && user!.fotoPerfilUrl!.isNotEmpty)
              ? CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(user.fotoPerfilUrl!),
                )
              : CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Text(getInitials(user?.nombreCompleto)),
                ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
          // --- Lista de Items ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: menuItems,
            ),
          ),
        ],
      ),
    );
  }

  // Helper para construir cada item del menú
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String pageKey,
  }) {
    final bool isSelected = selectedPageKey == pageKey;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      selected: isSelected,
      onTap: () => onNavigate(pageKey),
    );
  }
}

// Pequeño widget para los subtítulos del drawer
class _DrawerHeaderTitle extends StatelessWidget {
  final String title;
  const _DrawerHeaderTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
