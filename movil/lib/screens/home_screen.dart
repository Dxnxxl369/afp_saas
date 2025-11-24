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

import 'qr_scanner_screen.dart';



// Convertimos HomeScreen a StatefulWidget para manejar la página seleccionada

class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});



  @override

  State<HomeScreen> createState() => _HomeScreenState();

}



class _HomeScreenState extends State<HomeScreen> {
  String _selectedPageKey = 'dashboard';
  Timer? _notificationTimer;
  bool _didProcessInitialRoute = false;
  
  // --- NUEVO: Estado para el ID del activo a resaltar ---
  String? _highlightedAssetId;

  @override
  void initState() {
    super.initState();
    debugPrint("DEBUG: HomeScreen initState()");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
      _notificationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        Provider.of<NotificationProvider>(context, listen: false).fetchUnreadCount();
      });
      _setupFCMListeners();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didProcessInitialRoute) {
      debugPrint("DEBUG: didChangeDependencies() - Procesando ruta inicial por primera vez.");
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is Map<String, dynamic>) {
        
        // Manejar módulo inicial
        if (arguments.containsKey('initialModule')) {
          final initialModule = arguments['initialModule'] as String;
          debugPrint("DEBUG: didChangeDependencies() - Argumento 'initialModule' encontrado: '$initialModule'");
          // Llama a la navegación segura, que se ejecutará después del build
          _onNavigate(initialModule);
        }

        // --- NUEVO: Manejar ID de activo a resaltar ---
        if (arguments.containsKey('highlightedAssetId')) {
          setState(() {
            _highlightedAssetId = arguments['highlightedAssetId'] as String?;
             debugPrint("DEBUG: didChangeDependencies() - Argumento 'highlightedAssetId' encontrado: '$_highlightedAssetId'");
          });
        }
        
      } else {
        debugPrint("DEBUG: didChangeDependencies() - No se encontraron argumentos de ruta válidos.");
      }
      _didProcessInitialRoute = true;
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  // (El resto de la lógica de FCM y notificaciones no cambia)
  void _setupFCMListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      if (message.notification != null) {
        main_app.flutterLocalNotificationsPlugin.show(
          message.hashCode,
          message.notification!.title,
          message.notification!.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
            ),
          ),
          payload: message.data['url_destino'],
        );
      }
      _handleFCMMessage(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleFCMMessage(message);
    });
  }
  void _handleFCMMessage(RemoteMessage message) {
    Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    final String? urlDestino = message.data['url_destino'];
    if (urlDestino != null) {
      final String? moduleKey = _extractPageKeyFromUrl(urlDestino);
      final String? id = extractIdFromUrl(urlDestino);
      if (moduleKey == 'mantenimientos' && id != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          main_app.navigatorKey.currentState!.pushNamed('/mantenimiento-detail', arguments: id);
        });
      } else if (moduleKey != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _onNavigate(moduleKey);
        });
      }
    }
  }

  void _onNavigate(String pageKey) {
    debugPrint("DEBUG: _onNavigate() - Solicitado navegar a: '$pageKey'");
    if (pageKey.isEmpty || _selectedPageKey == pageKey) {
      debugPrint("DEBUG: _onNavigate() - Navegación omitida (misma página o clave vacía).");
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint("DEBUG: _onNavigate() - Ejecutando setState para cambiar a: '$pageKey'");
        setState(() { _selectedPageKey = pageKey; });
      }
    });
  }
  
  // --- NUEVO: Función para construir la página actual ---
  Widget _buildCurrentPage() {
    switch (_selectedPageKey) {
      case 'dashboard': return const DashboardScreen();
      case 'departamentos': return const DepartamentosScreen();
      case 'cargos': return const CargosScreen();
      case 'ubicaciones': return const UbicacionesScreen();
      case 'estados': return const EstadosScreen();
      case 'presupuestos': return const PeriodosScreen();
      case 'solicitudes_compra': return const SolicitudesScreen();
      case 'ordenes_compra': return const OrdenesScreen();
      case 'empleados': return const EmpleadosScreen();
      case 'activos_fijos': 
        // Pasa el ID a la pantalla de activos
        return ActivosScreen(highlightedAssetId: _highlightedAssetId);
      case 'mantenimientos': return const MantenimientoScreen();
      case 'proveedores': return const ProveedoresScreen();
      case 'categorias_activo': return const CategoriasActivoScreen();
      case 'suscripcion': return const SuscripcionScreen();
      case 'disposicion': return const DisposicionScreen();
      case 'depreciacion': return const DepreciacionScreen();
      case 'revalorizacion': return const RevalorizacionScreen();
      case 'roles': return const RolesScreen();
      case 'reportes': return const ReportesScreen();
      default: return const DashboardScreen();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    debugPrint("DEBUG: HomeScreen build() - Página actual: '$_selectedPageKey', Highlight ID: $_highlightedAssetId");
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final notificationProvider = context.watch<NotificationProvider>();
    final unreadCount = notificationProvider.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle(_selectedPageKey)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.qrCode),
            tooltip: 'Escanear QR',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const QrScannerScreen()));
            },
          ),
          IconButton(
            icon: Badge(
               label: Text(unreadCount.toString()),
               isLabelVisible: unreadCount > 0,
               child: const Icon(LucideIcons.bell),
            ),
            tooltip: 'Notificaciones',
            onPressed: () { _showNotificationsSheet(context); },
          ),
          PopupMenuButton<String>(
            icon: (user?.fotoPerfilUrl != null && user!.fotoPerfilUrl!.isNotEmpty)
              ? CircleAvatar(
                  radius: 16,
                  backgroundImage: CachedNetworkImageProvider(user.fotoPerfilUrl!),
                  onBackgroundImageError: (exception, stackTrace) { debugPrint("Error cargando foto de perfil: ${user.fotoPerfilUrl}"); },
                )
              : CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Text(getInitials(user?.nombreCompleto)),
                ),
            tooltip: 'Perfil',
            onSelected: (String result) {
              if (result == 'logout') {
                context.read<AuthProvider>().logout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
          const SizedBox(width: 8),
        ],
      ),
      drawer: AppDrawer(
        selectedPageKey: _selectedPageKey,
        onNavigate: _onNavigate,
      ),
      // --- USA LA NUEVA FUNCIÓN DE BUILD ---
      body: _buildCurrentPage(),
    );
  }
  
  // (El resto de la clase: _getPageTitle, _extractPageKeyFromUrl, etc. no cambia)
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
      case 'reportes': return 'Reportes';
      default: return 'ActFijo App';
    }
  }
  String? _extractPageKeyFromUrl(String url) {
    if (url.startsWith('/app/')) {
      String path = url.substring(5);
      int slashIndex = path.indexOf('/');
      if (slashIndex != -1) { return path.substring(0, slashIndex); }
      return path;
    }
    return null;
  }
  Widget _buildNotificationListTile(BuildContext context, app_notification.Notification notification, Function(String) onNavigateCallback) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () async {
          String? pageKey;
          if (notification.urlDestino != null) {
            pageKey = _extractPageKeyFromUrl(notification.urlDestino!);
            if (pageKey != null && mounted) { onNavigateCallback(pageKey); }
          }
          Navigator.of(context).pop();
          if (!notification.leido) {
            try {
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
              Icon( notification.leido ? LucideIcons.bell : LucideIcons.bellDot, color: notification.leido ? Colors.grey : Theme.of(context).colorScheme.primary, size: 28, ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text( notification.mensaje, style: TextStyle( fontWeight: notification.leido ? FontWeight.normal : FontWeight.bold, ), maxLines: 2, overflow: TextOverflow.ellipsis, ),
                    const SizedBox(height: 4),
                    Text( '${notification.tipoDisplay} - ${DateFormat('dd/MM/yy HH:mm').format(notification.timestamp.toLocal())}', style: Theme.of(context).textTheme.bodySmall, ),
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
              return const SizedBox( height: 200, child: Center(child: CircularProgressIndicator()), );
            }
            if (notificationProvider.errorMessage != null && notificationProvider.notifications.isEmpty) {
              return SizedBox( height: 200, child: Center( child: Text('Error: ${notificationProvider.errorMessage}'), ), );
            }
            if (notificationProvider.notifications.isEmpty) {
              return const SizedBox( height: 200, child: Center(child: Text('No hay notificaciones.')), );
            }
            final List<app_notification.Notification> unreadNotifications = notificationProvider.notifications.where((n) => !n.leido).toList();
            final List<app_notification.Notification> readNotifications = notificationProvider.notifications.where((n) => n.leido).toList();
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only( bottom: MediaQuery.of(context).viewInsets.bottom, ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text( 'Notificaciones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), ),
                        if (unreadNotifications.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              showDialog( context: context, builder: (context) => const Center(child: CircularProgressIndicator()), barrierDismissible: false, );
                              try {
                                await notificationProvider.markAllNotificationsAsRead();
                              } finally {
                                if (context.mounted) { Navigator.of(context).pop(); }
                              }
                            },
                            child: const Text('Marcar todas como leídas'),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        if (unreadNotifications.isNotEmpty) ...[
                          const Padding( padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Text( 'Nuevas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), ), ),
                          ListView.builder( shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: unreadNotifications.length, itemBuilder: (context, index) { return _buildNotificationListTile(context, unreadNotifications[index], _onNavigate); }, ),
                        ],
                        if (readNotifications.isNotEmpty) ...[
                          if (unreadNotifications.isNotEmpty) const Divider(height: 1),
                          ExpansionTile(
                            title: Text('Leídas (${readNotifications.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            initiallyExpanded: false,
                            children: [
                              ListView.builder( shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: readNotifications.length, itemBuilder: (context, index) { return _buildNotificationListTile(context, readNotifications[index], _onNavigate); }, ),
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
