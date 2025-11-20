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

    // 3. Módulos Principales (con agrupación)
    List<Widget> gestionActivosItems = [];
    if (auth.hasPermission('view_activofijo')) {
      gestionActivosItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.scan,
        title: 'Lista de Activos',
        pageKey: 'activos_fijos',
        isSubItem: true,
      ));
    }
    if (auth.hasPermission('view_revalorizacion')) {
      gestionActivosItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.trendingUp,
        title: 'Revalorización',
        pageKey: 'revalorizacion',
        isSubItem: true,
      ));
    }
    if (auth.hasPermission('view_depreciacion')) {
      gestionActivosItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.trendingDown,
        title: 'Depreciación',
        pageKey: 'depreciacion',
        isSubItem: true,
      ));
    }
    if (auth.hasPermission('view_disposicion')) {
      gestionActivosItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.archive,
        title: 'Disposición',
        pageKey: 'disposicion',
        isSubItem: true,
      ));
    }
    
    if (gestionActivosItems.isNotEmpty) {
      menuItems.add(
        ExpansionTile(
          leading: const Icon(LucideIcons.box),
          title: const Text('Gestión de Activos'),
          children: gestionActivosItems,
        )
      );
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
    // --- NUEVO: Reportes ---
    if (auth.hasPermission('view_custom_reports')) { // Using the permission checked in backend ReporteQueryView
      menuItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.chartBar, // O un icono más apropiado para reportes
        title: 'Reportes',
        pageKey: 'reportes',
      ));
    }
    // --- FIN NUEVO ---

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
    if (auth.hasPermission('view_cargo')) {
      settingsItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.briefcase,
        title: 'Cargos',
        pageKey: 'cargos',
      ));
    }
    if (auth.hasPermission('view_ubicacion')) {
      settingsItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.mapPin,
        title: 'Ubicaciones',
        pageKey: 'ubicaciones',
      ));
    }
    if (auth.hasPermission('view_estadoactivo')) {
      settingsItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.squareCheck,
        title: 'Estados',
        pageKey: 'estados',
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
    if (auth.hasPermission('view_proveedor')) {
      settingsItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.truck,
        title: 'Proveedores',
        pageKey: 'proveedores',
      ));
    }
    if (auth.hasPermission('view_categoriaactivo')) {
      settingsItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.tag,
        title: 'Categorías de Activo',
        pageKey: 'categorias_activo',
      ));
    }
    // --- NUEVO: Roles ---
    if (auth.hasPermission('view_rol')) {
      settingsItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.userCog, // O un icono más apropiado para roles
        title: 'Roles',
        pageKey: 'roles',
      ));
    }
    // --- FIN NUEVO ---
    if (auth.hasPermission('view_suscripcion')) {
      settingsItems.add(_buildDrawerItem(
        context: context,
        icon: LucideIcons.award,
        title: 'Suscripción',
        pageKey: 'suscripcion',
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
    bool isSubItem = false,
  }) {
    final bool isSelected = selectedPageKey == pageKey;
    return ListTile(
      contentPadding: isSubItem ? const EdgeInsets.only(left: 32.0) : null,
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
