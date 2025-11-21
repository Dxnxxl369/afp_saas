// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

// Importar Providers
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/departamento_provider.dart';
import 'providers/presupuesto_provider.dart';
import 'providers/solicitud_compra_provider.dart';
import 'providers/orden_compra_provider.dart';
import 'providers/activo_fijo_provider.dart';
import 'providers/cargos_provider.dart';
import 'providers/ubicaciones_provider.dart';
import 'providers/estados_provider.dart';
import 'providers/mantenimiento_provider.dart';
import 'providers/empleado_provider.dart';
import 'providers/suscripcion_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/proveedor_provider.dart';
import 'providers/categoria_activo_provider.dart';
import 'providers/revalorizacion_provider.dart';
import 'providers/depreciacion_provider.dart';
import 'providers/disposicion_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/roles_provider.dart';
import 'providers/reportes_provider.dart';
import 'services/api_service.dart';

// Importar Pantallas
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';

import 'app_theme.dart';

// Global Key para el Navigator (Permite navegar desde cualquier lugar)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Handling a background message: ${message.messageId}');
  // Show local notification for background messages
  if (message.notification != null) {
    flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['url_destino'], // Pass url_destino as payload
    );
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Función para manejar taps en notificaciones locales
void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  if (payload != null && payload.isNotEmpty) {
    debugPrint('Notification payload: $payload');
    // Navegar usando la GlobalKey
    if (navigatorKey.currentState != null) {
      if (payload.contains('/app/mantenimientos')) {
        // Asumiendo que /app/mantenimientos lleva a la HomeScreen principal por ahora
        // Y dentro de HomeScreen se gestionará la visualización específica
        navigatorKey.currentState!.pushNamed('/home');
        // Si quisieras ir a un detalle específico, necesitarías un sistema de ruteo más avanzado (ej. GoRouter)
        // y pasar el ID del mantenimiento:
        // navigatorKey.currentState!.pushNamed('/home', arguments: {'module': 'mantenimientos', 'id': extractId(payload)});
      } else if (payload.contains('/app/solicitudes-compra')) {
        navigatorKey.currentState!.pushNamed('/home');
      }
      // Añadir más lógica para otras rutas si es necesario
    }
  }
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- Solicitar permisos de notificación (para iOS y Android 13+) ---
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  debugPrint('User granted permission: ${settings.authorizationStatus}');

  // --- FlutterLocalNotificationsPlugin initialization ---
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  // Configure onDidReceiveNotificationResponse for tap handling
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse, // <-- Manejar taps
  );

  // --- Create Android Notification Channel (for heads-up notifications) ---
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // --- Manejo de mensajes FCM en primer plano ---
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon,
          ),
        ),
        payload: message.data['url_destino'], // Pasar url_destino como payload
      );
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ThemeProvider>(
          create: (context) => ThemeProvider(context.read<AuthProvider>()),
          update: (context, auth, previousThemeProvider) {
            previousThemeProvider!.updateThemeFromAuth(auth.user);
            return previousThemeProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => DepartamentoProvider()),
        ChangeNotifierProvider(create: (_) => CargosProvider()),
        ChangeNotifierProvider(create: (_) => UbicacionesProvider()),
        ChangeNotifierProvider(create: (_) => EstadosProvider()),
        ChangeNotifierProvider(create: (_) => PresupuestoProvider()),
        ChangeNotifierProvider(create: (_) => SolicitudCompraProvider()),
        ChangeNotifierProvider(create: (_) => OrdenCompraProvider()),
        ChangeNotifierProvider(create: (_) => ActivoFijoProvider()),
        ChangeNotifierProvider(create: (_) => MantenimientoProvider()),
        ChangeNotifierProvider(create: (_) => EmpleadoProvider()),
        ChangeNotifierProvider(create: (_) => SuscripcionProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ProveedorProvider()),
        ChangeNotifierProvider(create: (_) => CategoriaActivoProvider()),
        ChangeNotifierProvider(create: (_) => RevalorizacionProvider()),
        ChangeNotifierProvider(create: (_) => DepreciacionProvider()),
        ChangeNotifierProvider(create: (_) => DisposicionProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider(ApiService())),
        ChangeNotifierProvider(create: (_) => RolesProvider(ApiService())),
        ChangeNotifierProvider(create: (_) => ReportesProvider(ApiService())),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          ThemeData currentTheme;
          
          if (themeProvider.themeMode == ThemeMode.light) {
             currentTheme = AppTheme.lightTheme;
          } else if (themeProvider.themeMode == ThemeMode.dark) {
             currentTheme = AppTheme.darkTheme;
          } else {
             currentTheme = AppTheme.getCustomTheme(themeProvider.customColor);
          }

          return MaterialApp(
            title: 'ActFijo App',
            debugShowCheckedModeBanner: false,
            theme: currentTheme,
            navigatorKey: navigatorKey, // <-- Asignar la GlobalKey
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.isLoading) {
                  debugPrint("main.dart: Auth está cargando, mostrando SplashScreen.");
                  return const SplashScreen();
                }
                
                if (!auth.isAuthenticated) {
                  debugPrint("main.dart: No autenticado, mostrando LoginScreen.");
                  return const LoginScreen();
                }
                
                debugPrint("main.dart: Autenticado, mostrando HomeScreen.");
                return const HomeScreen();
              },
            ),
            routes: {
               '/login': (context) => const LoginScreen(),
               '/home': (context) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}