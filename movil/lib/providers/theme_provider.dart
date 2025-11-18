// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/debounce.dart';
import './auth_provider.dart'; // Importar AuthProvider para el tipo AppUser

// --- [CORRECCIÓN] Mover helpers fuera de la clase ---
// Para que 'settings_screen.dart' pueda importarlos y usarlos

/// Convierte un objeto Color a un string Hex '#RRGGBB'
String colorToHexString(Color color) {
  // .value.toRadixString(16) devuelve AARRGGBB, quitamos el Alfa (primeros 2)
  int red = (color.r * 255.0).round() & 0xFF;
  int green = (color.g * 255.0).round() & 0xFF;
  int blue = (color.b * 255.0).round() & 0xFF;
  return '#${red.toRadixString(16).padLeft(2, '0')}${green.toRadixString(16).padLeft(2, '0')}${blue.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
}

/// Convierte un string Hex '#RRGGBB' a un objeto Color
Color hexStringToColor(String? hexColor) {
  hexColor = (hexColor ?? '#6366F1').replaceAll("#", ""); // Default si es null
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor"; // Añadir Alfa FF (opaco)
  }
  try {
     if (hexColor.length == 8) {
       return Color(int.parse("0x$hexColor"));
     }
  } catch(e) {
     debugPrint("Error parsing hex color: $hexColor, defaulting.");
  }
  return const Color(0xFF6366F1); // Default índigo
}
// --- [FIN CORRECCIÓN] ---


class ThemeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Debouncer _debouncer = Debouncer(milliseconds: 1000);
  final AuthProvider _authProvider; // Para saber si hay usuario

  ThemeMode _themeMode = ThemeMode.dark;
  Color _customColor = const Color(0xFF6366F1);
  bool _glowEnabled = false;

  ThemeMode get themeMode => _themeMode;
  Color get customColor => _customColor;
  bool get glowEnabled => _glowEnabled;

  ThemeProvider(this._authProvider);

  /// Esta función es llamada por el ProxyProvider en main.dart
  void updateThemeFromAuth(AppUser? user) {
    debugPrint("ThemeProvider: Actualizando tema desde AuthProvider. User: ${user?.username}");
    
    String themePref = user?.themePreference ?? 'dark';
    String? colorHex = user?.themeCustomColor;
    bool glow = user?.themeGlowEnabled ?? false;

    ThemeMode newMode;
    if (themePref == 'light') {
      newMode = ThemeMode.light;
    } else if (themePref == 'custom') {
      newMode = ThemeMode.system; // Usamos system como 'custom'
    } else {
      newMode = ThemeMode.dark;
    }
    
    Color newColor = hexStringToColor(colorHex);

    if (newMode != _themeMode || newColor != _customColor || glow != _glowEnabled) {
      _themeMode = newMode;
      _customColor = newColor;
      _glowEnabled = glow;
      debugPrint("ThemeProvider: Tema actualizado. Notificando...");
      notifyListeners();
    } else {
       debugPrint("ThemeProvider: Tema ya está sincronizado.");
    }
  }

  // --- [CORRECCIÓN] El debouncer.run() solo acepta 1 argumento ---
  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    String prefValue = (mode == ThemeMode.light) ? 'light' : 'dark';
    // La función que pasamos a run() no debe tener argumentos
    _debouncer.run(() {
      _savePreference({'theme_preference': prefValue});
    });
  }

  void setCustomTheme(Color color) {
    _themeMode = ThemeMode.system;
    _customColor = color;
    notifyListeners();
    String colorHex = colorToHexString(color); // Usar el helper
    _debouncer.run(() {
      _savePreference({
        'theme_preference': 'custom',
        'theme_custom_color': colorHex
      });
    });
  }

  void setCustomColor(Color color) {
    if (_customColor == color) return;
    _customColor = color;
    if (_themeMode != ThemeMode.system) {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
    String colorHex = colorToHexString(color); // Usar el helper
    _debouncer.run(() {
      _savePreference({
         'theme_preference': 'custom',
         'theme_custom_color': colorHex
      });
    });
  }

  void setGlowEnabled(bool enabled) {
    if (_glowEnabled == enabled) return;
    _glowEnabled = enabled;
    notifyListeners();
    _debouncer.run(() {
      _savePreference({'theme_glow_enabled': enabled});
    });
  }
  // --- [FIN CORRECCIÓN] ---

  Future<void> _savePreference(Map<String, dynamic> preference) async {
    if (!_authProvider.isAuthenticated) {
       debugPrint("ThemeProvider: Skipping save (no user).");
       return;
    }
    try {
      // --- [CORRECCIÓN] Usar _apiService ---
      final response = await _apiService.updateMyThemePreferences(preference);
      debugPrint("ThemeProvider: Preferences saved successfully.");
      
      // Actualizar el AuthProvider localmente
      _authProvider.updateUserTheme(response); // Usamos la respuesta de la API
      
    } catch (e) {
      debugPrint("ThemeProvider: Failed to save preference - $e");
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}