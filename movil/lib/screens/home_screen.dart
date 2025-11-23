// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // <--- NUEVO
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <--- NUEVO
import 'package:movil/main.dart' as main_app; // Alias para evitar conflicto con main()
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // <--- NUEVO
import 'dart:convert'; // For jsonEncode
import 'package:intl/intl.dart'; // <-- AÑADIR ESTA LÍNEA

import '../providers/notification_provider.dart'; // <--- NUEVO
import '../models/notification.dart' as app_notification; // <--- NUEVO

import '../widgets/app_drawer.dart'; // El menú lateral
import '../providers/auth_provider.dart'; // Para los datos del usuario
import '../utils/helpers.dart'; // Para la función getInitials y extractIdFromUrl

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
import 'empleados/empleados_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'proveedores/proveedores_screen.dart';
import 'categorias_activo/categorias_activo_screen.dart';
import 'disposicion/disposicion_screen.dart';
import 'depreciacion/depreciacion_screen.dart';
import 'revalorizacion/revalorizacion_screen.dart';
import 'roles/roles_screen.dart'; // <--- NUEVO
import 'reportes/reportes_screen.dart'; // <--- NUEVO

// Convertimos HomeScreen a StatefulWidget para manejar la página seleccionada
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedPageKey = 'dashboard';
  Timer? _notificationTimer;
  bool _didProcessInitialRoute = false; // Flag para ejecutar la lógica solo una vez

  @override
  void initState() {
    super.initState();
    debugPrint("DEBUG: HomeScreen initState()");
    // Fetch notifications once when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
      // Set up a periodic timer to fetch notifications
      _notificationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        Provider.of<NotificationProvider>(context, listen: false).fetchUnreadCount(); // Fetch just the count for efficiency
      });

      // --- NUEVO: FCM Foreground & OpenedApp Message Handling ---
      _setupFCMListeners();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didProcessInitialRoute) {
      debugPrint("DEBUG: didChangeDependencies() - Procesando ruta inicial por primera vez.");
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is Map && arguments.containsKey('initialModule')) {
        final initialModule = arguments['initialModule'] as String;
        debugPrint("DEBUG: didChangeDependencies() - Argumento 'initialModule' encontrado: '$initialModule'");
        if (_pages.containsKey(initialModule)) {
          // Usa la nueva función de navegación segura
          _onNavigate(initialModule);
        } else {
          debugPrint("DEBUG: didChangeDependencies() - El módulo '$initialModule' no es una página válida.");
        }
      } else {
        debugPrint("DEBUG: didChangeDependencies() - No se encontraron argumentos de ruta para 'initialModule'.");
      }
      _didProcessInitialRoute = true;
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // --- NUEVO: FCM Message Handling Helpers ---
  void _setupFCMListeners() {
    // 1. Handle messages received while the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // --- NUEVO: Display local notification for foreground messages ---
        main_app.flutterLocalNotificationsPlugin.show(
          message.hashCode, // Unique ID for the notification
          message.notification!.title,
          message.notification!.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // Must match the ID defined in main.dart
              'High Importance Notifications',
              channelDescription: 'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
            ),
          ),
          payload: message.data['url_destino'], // Pass ONLY the URL as payload
        );
        // --- FIN NUEVO ---
      }
      // Optionally update in-app notification list
      _handleFCMMessage(message);
    });

    // 2. Handle messages that cause the application to open from a terminated or background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleFCMMessage(message);
    });
  }

  void _handleFCMMessage(RemoteMessage message) {
    // Refresh in-app notifications if a new message arrives
    Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();

    // Check if the message contains data for navigation
    final String? urlDestino = message.data['url_destino'];
    if (urlDestino != null) {
      final String? moduleKey = _extractPageKeyFromUrl(urlDestino);
      final String? id = extractIdFromUrl(urlDestino); // Use the helper from main.dart

      if (moduleKey == 'mantenimientos' && id != null) {
        debugPrint('FCM: Navegando a detalle de mantenimiento desde Home: $id');
        Future.delayed(const Duration(milliseconds: 500), () {
          main_app.navigatorKey.currentState!.pushNamed('/mantenimiento-detail', arguments: id);
        });
      } else if (moduleKey != null && _pages.containsKey(moduleKey)) {
        // Delay navigation slightly to allow UI to update or modal to close
        Future.delayed(const Duration(milliseconds: 500), () {
          _onNavigate(moduleKey);
        });
      } else {
        debugPrint('FCM: URL destino no mapeado a una página o sin ID válido: $urlDestino');
      }
    }
  }

  // Callback mejorado para cambiar de página de forma segura
  void _onNavigate(String pageKey) {
    debugPrint("DEBUG: _onNavigate() - Solicitado navegar a: '$pageKey'");
    // Evita reconstrucciones innecesarias si la página ya está seleccionada
    if (pageKey.isEmpty || _selectedPageKey == pageKey) {
      debugPrint("DEBUG: _onNavigate() - Navegación omitida (misma página o clave vacía).");
      return;
    }
    
    // Asegura que setState se llame después de que el frame actual se haya renderizado,
    // evitando conflictos con otras animaciones o reconstrucciones (como cerrar un modal).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Comprueba si el widget todavía está en el árbol de widgets
        debugPrint("DEBUG: _onNavigate() - Ejecutando setState para cambiar a: '$pageKey'");
        setState(() {
          _selectedPageKey = pageKey;
        });
      } else {
        debugPrint("DEBUG: _onNavigate() - El widget fue desmontado antes de que setState pudiera ejecutarse.");
      }
    });
  }
  
  // Mapa de todas las pantallas/widgets de los módulos
  // La clave (ej: 'dashboard') debe coincidir con la key usada en AppDrawer
  final Map<String, Widget> _pages = {
    'dashboard': const DashboardScreen(),
    'departamentos': const DepartamentosScreen(),
    'cargos': const CargosScreen(),
    'ubicaciones': const UbicacionesScreen(),
    'estados': const EstadosScreen(),
    'presupuestos': const PeriodosScreen(),
    'solicitudes_compra': const SolicitudesScreen(),
    'ordenes_compra': const OrdenesScreen(),
    'empleados': const EmpleadosScreen(),
    'activos_fijos': const ActivosScreen(),
    'mantenimientos': const MantenimientoScreen(),
    'proveedores': const ProveedoresScreen(),
    'categorias_activo': const CategoriasActivoScreen(),
    'suscripcion': const SuscripcionScreen(),
    'disposicion': const DisposicionScreen(),
    'depreciacion': const DepreciacionScreen(),
    'revalorizacion': const RevalorizacionScreen(),
    'roles': const RolesScreen(),
    'reportes': const ReportesScreen(), // <--- NUEVO
    // ... (Añadir otras pantallas de módulos aquí) ...
  };
  
  @override
  Widget build(BuildContext context) {
    debugPrint("DEBUG: HomeScreen build() - Página actual: '$_selectedPageKey'");
    // Usamos 'watch' (context.watch) para que el widget se reconstruya
    // si el usuario cambia (ej. al cerrar sesión)
    final auth = context.watch<AuthProvider>();
    final user = auth.user; // Puede ser null brevemente durante el logout
    final notificationProvider = context.watch<NotificationProvider>();
    final unreadCount = notificationProvider.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle(_selectedPageKey)),
        actions: [
          // --- Icono de Notificaciones ---
          IconButton(
            icon: Badge(
               label: Text(unreadCount.toString()), // Lógica futura de contador
               isLabelVisible: unreadCount > 0,
               child: const Icon(LucideIcons.bell),
            ),
            tooltip: 'Notificaciones',
            onPressed: () {
              _showNotificationsSheet(context); // Call the new method
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
      case 'empleados': return 'Empleados';
      case 'activos_fijos': return 'Activos Fijos';
      case 'mantenimientos': return 'Mantenimientos';
      case 'proveedores': return 'Proveedores';
      case 'categorias_activo': return 'Categorías de Activo';
      case 'suscripcion': return 'Suscripción';
      case 'disposicion': return 'Disposición de Activos';
      case 'depreciacion': return 'Depreciación de Activos';
      case 'revalorizacion': return 'Revalorización de Activos';
      case 'roles': return 'Roles';
      case 'reportes': return 'Reportes'; // <--- NUEVO
      default: return 'ActFijo App';
    }
  }

  String? _extractPageKeyFromUrl(String url) {
    if (url.startsWith('/app/')) {
      String path = url.substring(5); // Remove '/app/'
      int slashIndex = path.indexOf('/');
      if (slashIndex != -1) {
        return path.substring(0, slashIndex);
      }
      return path;
    }
    return null;
  }

  // Helper method for building individual notification list tiles
  Widget _buildNotificationListTile(BuildContext context, app_notification.Notification notification, Function(String) onNavigateCallback) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () async {
          String? pageKey;
          if (notification.urlDestino != null) {
            pageKey = _extractPageKeyFromUrl(notification.urlDestino!);
            debugPrint("DEBUG: Notification Tapped - URL: '${notification.urlDestino}', PageKey extraído: '$pageKey'");
            if (pageKey != null && _pages.containsKey(pageKey)) {
              onNavigateCallback(pageKey); // Llama a la función _onNavigate actualizada
            } else {
              debugPrint("DEBUG: Notification Tapped - PageKey no válido o no encontrado en _pages.");
            }
          }
          
          // Cierra el modal de notificaciones
          Navigator.of(context).pop();

          // Marca la notificación como leída (esto puede ocurrir después de que el modal se cierre)
          if (!notification.leido) {
            try {
              // Usamos listen: false porque estamos en un callback
              await Provider.of<NotificationProvider>(context, listen: false).markNotificationAsRead(notification.id);
            } catch (e) {
              debugPrint("Error al marcar notificación como leída: $e");
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(
                notification.leido ? LucideIcons.bell : LucideIcons.bellDot,
                color: notification.leido ? Colors.grey : Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.mensaje,
                      style: TextStyle(
                        fontWeight: notification.leido ? FontWeight.normal : FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${notification.tipoDisplay} - ${DateFormat('dd/MM/yy HH:mm').format(notification.timestamp.toLocal())}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (notification.urlDestino != null)
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        return Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            if (notificationProvider.isLoading && notificationProvider.notifications.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (notificationProvider.errorMessage != null && notificationProvider.notifications.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text('Error: ${notificationProvider.errorMessage}'),
                ),
              );
            }

            if (notificationProvider.notifications.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('No hay notificaciones.')),
              );
            }

            final List<app_notification.Notification> unreadNotifications = notificationProvider.notifications
                .where((n) => !n.leido)
                .toList();
            final List<app_notification.Notification> readNotifications = notificationProvider.notifications
                .where((n) => n.leido)
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75, // Occupy 75% of screen height
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notificaciones',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (unreadNotifications.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              showDialog(
                                context: context,
                                builder: (context) => const Center(child: CircularProgressIndicator()),
                                barrierDismissible: false,
                              );
                              try {
                                await notificationProvider.markAllNotificationsAsRead();
                              } finally {
                                if (context.mounted) {
                                  Navigator.of(context).pop(); // Cierra el diálogo de carga
                                }
                              }
                            },
                            child: const Text('Marcar todas como leídas'),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView( // Use ListView directly here to handle both sections
                      shrinkWrap: true,
                      children: [
                        if (unreadNotifications.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              'Nuevas',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(), // Important for nested scroll views
                            itemCount: unreadNotifications.length,
                            itemBuilder: (context, index) {
                              return _buildNotificationListTile(context, unreadNotifications[index], _onNavigate);
                            },
                          ),
                        ],
                        if (readNotifications.isNotEmpty) ...[
                          if (unreadNotifications.isNotEmpty) const Divider(height: 1), // Separator if both exist
                          ExpansionTile(
                            title: Text('Leídas (${readNotifications.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            initiallyExpanded: false, // Start collapsed
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: readNotifications.length,
                                itemBuilder: (context, index) {
                                  return _buildNotificationListTile(context, readNotifications[index], _onNavigate);
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}