// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Corrected import
import 'package:firebase_core/firebase_core.dart'; // <--- NUEVO
import 'package:firebase_messaging/firebase_messaging.dart'; // <--- NUEVO
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // <--- NUEVO
import 'firebase_options.dart'; // <--- NUEVO

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
import 'providers/roles_provider.dart'; // <--- NUEVO
import 'providers/reportes_provider.dart'; // <--- NUEVO
import 'services/api_service.dart'; // <--- NUEVO

// Importar Pantallas
import 'screens/home_screen.dart'; // <-- Archivo que te faltaba
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart'; // <-- Pantalla de carga

import 'app_theme.dart'; // Tu archivo de diseño

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Handling a background message: ${message.messageId}');
  // You can perform heavy data processing here if needed
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin(); // <--- NUEVO

Future<void> main() async { // <--- MODIFICADO A async
  WidgetsFlutterBinding.ensureInitialized(); // <--- NUEVO
  await Firebase.initializeApp( // <--- NUEVO
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- NUEVO: FlutterLocalNotificationsPlugin initialization ---
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // Use your app icon
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // --- NUEVO: Create Android Notification Channel (for heads-up notifications) ---
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max, // for heads-up notifications
      ));
  // --- FIN NUEVO ---

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler); // <--- NUEVO

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider para anidar todos los providers
    return MultiProvider(
      providers: [
        // 1. AuthProvider (El principal, debe ir primero)
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // 2. ThemeProvider (Depende de AuthProvider para el 'user')
        ChangeNotifierProxyProvider<AuthProvider, ThemeProvider>(
          // 'create' solo se llama la primera vez
          create: (context) => ThemeProvider(context.read<AuthProvider>()),
          // 'update' se llama cada vez que AuthProvider notifica un cambio
          update: (context, auth, previousThemeProvider) {
            // Reutiliza el provider anterior y actualízalo con los datos de auth
            previousThemeProvider!.updateThemeFromAuth(auth.user);
            return previousThemeProvider;
          },
        ),

        // 3. Providers de Datos (Ahora son 'lazy' por defecto)
        // Se crearán pero no cargarán datos hasta que se usen
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
        ChangeNotifierProvider(create: (_) => ReportesProvider(ApiService())), // <--- NUEVO
        // (Añadir más providers de módulos aquí)
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // --- Lógica de Tema ---
          ThemeData currentTheme;
          // Esperar a que el tema esté listo (evita FOUC)
          // (Esta lógica está ahora dentro del 'update' del ProxyProvider)
          
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
            theme: currentTheme, // Aplicar tema
            
            // --- [ LA SOLUCIÓN ESTÁ AQUÍ ] ---
            // Usamos un Consumer de AuthProvider para decidir qué pantalla mostrar
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                // 1. Mientras AuthProvider está verificando el token
                // (auth.isLoading es true al inicio)
                if (auth.isLoading) {
                  debugPrint("main.dart: Auth está cargando, mostrando SplashScreen.");
                  return const SplashScreen();
                }
                
                // 2. Si NO está autenticado (y ya no está cargando)
                if (!auth.isAuthenticated) {
                  debugPrint("main.dart: No autenticado, mostrando LoginScreen.");
                  return const LoginScreen();
                }
                
                // 3. Si SÍ está autenticado (y ya no está cargando)
                debugPrint("main.dart: Autenticado, mostrando HomeScreen.");
                return const HomeScreen();
              },
            ),
            // --- [ FIN DE LA SOLUCIÓN ] ---
            
            routes: {
               // Definimos rutas por si las necesitamos para navegación profunda
               '/login': (context) => const LoginScreen(),
               '/home': (context) => const HomeScreen(),
               // (Añadir ruta a /settings si la navegas por nombre)
               // '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}