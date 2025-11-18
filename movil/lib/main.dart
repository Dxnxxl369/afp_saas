// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importar Providers
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/departamento_provider.dart';
//import 'providers/empleado_provider.dart';

// Importar Pantallas
import 'screens/home_screen.dart'; // <-- Archivo que te faltaba
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart'; // <-- Pantalla de carga

import 'app_theme.dart'; // Tu archivo de diseño

void main() {
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
        //ChangeNotifierProvider(create: (_) => EmpleadoProvider()),
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