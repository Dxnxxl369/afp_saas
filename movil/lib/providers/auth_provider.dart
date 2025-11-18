// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// --- [IMPORTACIÓN CORRECTA] ---
import 'package:jwt_decode/jwt_decode.dart';
// Importa la función 'jwtDecode'
// --- [FIN IMPORTACIÓN] ---
import '../services/auth_service.dart';
import '../services/api_service.dart';

// Modelo AppUser (puedes moverlo a models/app_user.dart si prefieres)
class AppUser {
  final String username;
  final String email;
  final String nombreCompleto;
  final String empresaNombre;
  final String? empleadoId;
  final String? themePreference;
  final String? themeCustomColor;
  final bool? themeGlowEnabled;
  final String? fotoPerfilUrl;
  
  AppUser({
    required this.username,
    required this.email,
    required this.nombreCompleto,
    required this.empresaNombre,
    this.empleadoId,
    this.themePreference,
    this.themeCustomColor,
    this.themeGlowEnabled,
    this.fotoPerfilUrl,
  });

  factory AppUser.fromToken(Map<String, dynamic> decodedToken) {
    return AppUser(
      username: decodedToken['username'] ?? '',
      email: decodedToken['email'] ?? '',
      nombreCompleto: decodedToken['nombre_completo'] ?? '',
      empresaNombre: decodedToken['empresa_nombre'] ?? '',
      empleadoId: decodedToken['empleado_id'],
      themePreference: decodedToken['theme_preference'],
      themeCustomColor: decodedToken['theme_custom_color'],
      themeGlowEnabled: decodedToken['theme_glow_enabled'] ?? false,
      fotoPerfilUrl: decodedToken['foto_perfil'], // Leer la foto del token
    );
  }
}


class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  
  bool _isAuthenticated = false;
  AppUser? _user;
  List<String> _userRoles = [];
  bool _userIsAdmin = false; // SuperAdmin de Django
  Set<String> _userPermissions = {};
  bool _isLoading = true;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  AppUser? get user => _user;
  List<String> get userRoles => _userRoles;
  bool get userIsAdmin => _userIsAdmin;
  Set<String> get userPermissions => _userPermissions;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    debugPrint("AuthProvider: Intentando auto-login...");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      debugPrint("AuthProvider: No se encontró token.");
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // --- [ CORRECCIÓN 1 ] ---
      // Usar 'jwtDecode' (j minúscula), no 'JwtDecode.decode'
      final decodedToken = Jwt.parseJwt(token);
      // --- [ FIN CORRECCIÓN ] ---

      if (decodedToken['exp'] * 1000 < DateTime.now().millisecondsSinceEpoch) {
        debugPrint("AuthProvider: Token expirado.");
        await prefs.remove('token');
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      debugPrint("AuthProvider: Token válido encontrado, logueando...");
      await _handleTokenData(token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("AuthProvider: Error al decodificar token: $e");
      await prefs.remove('token');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handleTokenData(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);

    // --- [ CORRECCIÓN 2 ] ---
    // Usar 'jwtDecode' (j minúscula)
    final decodedToken = Jwt.parseJwt(token);
    // --- [ FIN CORRECCIÓN ] ---
    
    _user = AppUser.fromToken(decodedToken);
    _userRoles = List<String>.from(decodedToken['roles'] ?? []);
    _userIsAdmin = decodedToken['is_admin'] ?? false;
    _isAuthenticated = true;

    try {
      _userPermissions = await _apiService.getMyPermissions(token);
      debugPrint("AuthProvider: Permisos cargados: ${_userPermissions.length}");
    } catch (e) {
      debugPrint("AuthProvider: Error al cargar permisos: $e");
      _userPermissions = <String>{};
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _authService.login(username, password);
      final token = response['access'];
      if (token == null) throw Exception("Respuesta de login inválida.");
      
      await _handleTokenData(token);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> logout() async {
    _isAuthenticated = false;
    _user = null;
    _userRoles = [];
    _userIsAdmin = false;
    _userPermissions = <String>{};
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    
    debugPrint("AuthProvider: Sesión cerrada.");
    notifyListeners();
  }

  void updateUserTheme(Map<String, dynamic> newThemePrefs) {
    if (_user == null) return;
    
    _user = AppUser(
      username: _user!.username,
      email: _user!.email,
      nombreCompleto: _user!.nombreCompleto,
      empresaNombre: _user!.empresaNombre,
      empleadoId: _user!.empleadoId,
      fotoPerfilUrl: _user!.fotoPerfilUrl,
      // Aplicar cambios
      themePreference: newThemePrefs['theme_preference'] ?? _user!.themePreference,
      themeCustomColor: newThemePrefs['theme_custom_color'] ?? _user!.themeCustomColor,
      themeGlowEnabled: newThemePrefs['theme_glow_enabled'] ?? _user!.themeGlowEnabled,
    );
    debugPrint("AuthContext: Estado 'user' actualizado con nuevo tema.");
    notifyListeners();
  }

  // --- Funciones de Permisos ---
  bool hasPermission(String permissionName) {
    if (_userIsAdmin) return true; // SuperAdmin tiene todo
    return _userPermissions.contains(permissionName);
  }
  
  bool hasRole(String roleName) {
    return _userRoles.contains(roleName);
  }
}