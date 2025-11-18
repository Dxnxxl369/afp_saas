// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../widgets/app_drawer.dart'; // El menú lateral
import '../providers/auth_provider.dart'; // Para los datos del usuario
import '../utils/helpers.dart'; // Para la función getInitials

// Importar las pantallas de los módulos
import 'departamentos_screen.dart';
import 'cargos/cargos_screen.dart';
import 'ubicaciones/ubicaciones_screen.dart';
import 'estados/estados_screen.dart';
import 'presupuesto/periodos_screen.dart';
import 'solicitudes_compra/solicitudes_screen.dart';
import 'ordenes_compra/ordenes_screen.dart';
import 'activos/activos_screen.dart';
import 'mantenimiento/mantenimiento_screen.dart';
import 'suscripcion/suscripcion_screen.dart';
//import 'empleados/empleados_screen.dart';

// Convertimos HomeScreen a StatefulWidget para manejar la página seleccionada
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Estado para saber qué página mostrar en el body
  String _selectedPageKey = 'dashboard'; // 'dashboard' es la página inicial

  // Callback que el AppDrawer usará para cambiar de página
  void _onNavigate(String pageKey) {
    if (pageKey.isEmpty) return;
    setState(() {
      _selectedPageKey = pageKey;
    });
    Navigator.pop(context); // Cierra el drawer automáticamente
  }
  
  // Mapa de todas las pantallas/widgets de los módulos
  // La clave (ej: 'dashboard') debe coincidir con la key usada en AppDrawer
  final Map<String, Widget> _pages = {
    'dashboard': const Center(child: Text('Dashboard (Contenido Principal)')),
    'departamentos': const DepartamentosScreen(),
    'cargos': const CargosScreen(),
    'ubicaciones': const UbicacionesScreen(),
    'estados': const EstadosScreen(),
    'presupuestos': const PeriodosScreen(),
    'solicitudes_compra': const SolicitudesScreen(),
    'ordenes_compra': const OrdenesScreen(),
    //'empleados': const EmpleadosScreen(),
    'activos_fijos': const ActivosScreen(),
    'mantenimientos': const MantenimientoScreen(),
    'suscripcion': const SuscripcionScreen(),
    // ... (Añadir otras pantallas de módulos aquí) ...
  };
  
  @override
  Widget build(BuildContext context) {
    // Usamos 'watch' (context.watch) para que el widget se reconstruya
    // si el usuario cambia (ej. al cerrar sesión)
    final auth = context.watch<AuthProvider>();
    final user = auth.user; // Puede ser null brevemente durante el logout

    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle(_selectedPageKey)),
        actions: [
          // --- Icono de Notificaciones ---
          IconButton(
            icon: Badge(
               // label: Text('3'), // (Lógica futura de contador)
               // isLabelVisible: unreadCount > 0,
               child: const Icon(LucideIcons.bell),
            ),
            tooltip: 'Notificaciones',
            onPressed: () {
              // TODO: Mostrar overlay/pantalla de notificaciones
            },
          ),
          
          // --- Menú de Perfil ---
          PopupMenuButton<String>(
            // Mostrar foto de perfil o iniciales
            icon: (user?.fotoPerfilUrl != null && user!.fotoPerfilUrl!.isNotEmpty)
              ? CircleAvatar(
                  radius: 16,
                  backgroundImage: CachedNetworkImageProvider(user.fotoPerfilUrl!),
                  // Manejo de error de la imagen
                  onBackgroundImageError: (exception, stackTrace) {
                     debugPrint("Error cargando foto de perfil: ${user.fotoPerfilUrl}");
                  },
                )
              : CircleAvatar( // Fallback a iniciales
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Text(getInitials(user?.nombreCompleto)),
                ),
            tooltip: 'Perfil',
            onSelected: (String result) {
              if (result == 'logout') {
                // Usar 'read' dentro de callbacks
                context.read<AuthProvider>().logout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              // Info del usuario (no clickeable)
              PopupMenuItem<String>(
                 enabled: false,
                 child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(LucideIcons.user),
                    title: Text(user?.nombreCompleto ?? 'Cargando...', style: Theme.of(context).textTheme.bodyMedium),
                    subtitle: Text(user?.email ?? '...', style: Theme.of(context).textTheme.bodySmall),
                 ),
              ),
              const PopupMenuDivider(),
              // Botón Cerrar Sesión
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(LucideIcons.logOut, size: 20, color: Colors.red),
                  title: Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8), // Pequeño espacio
        ],
      ),
      // --- El Menú Lateral ---
      drawer: AppDrawer(
        selectedPageKey: _selectedPageKey,
        onNavigate: _onNavigate, // Pasamos la función de callback
      ),
      // --- Contenido Principal Dinámico ---
      // Muestra la pantalla correspondiente a la key seleccionada
      body: _pages[_selectedPageKey] ?? _pages['dashboard'],
    );
  }

  // Helper para mostrar el título correcto en la AppBar
  String _getPageTitle(String key) {
    switch(key) {
      case 'dashboard': return 'Dashboard';
      case 'departamentos': return 'Departamentos';
      case 'cargos': return 'Cargos';
      case 'ubicaciones': return 'Ubicaciones';
      case 'estados': return 'Estados';
      case 'presupuestos': return 'Presupuestos';
      case 'solicitudes_compra': return 'Solicitudes de Compra';
      case 'ordenes_compra': return 'Órdenes de Compra';
      //case: 'empleados': return 'Empleados';
      case 'activos_fijos': return 'Activos Fijos';
      case 'mantenimientos': return 'Mantenimientos';
      case 'suscripcion': return 'Suscripción';
      // ... (añadir otros) ...
      default: return 'ActFijo App';
    }
  }
}