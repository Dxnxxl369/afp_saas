// movil/lib/providers/roles_provider.dart
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/rol.dart';
import '../models/permiso.dart';

class RolesProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Rol> _roles = [];
  List<Permiso> _allPermissions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Rol> get roles => _roles;
  List<Permiso> get allPermissions => _allPermissions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  RolesProvider(this._apiService);

  Future<void> fetchRoles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _roles = await _apiService.getRoles();
      _roles.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error fetching roles: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllPermissions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allPermissions = await _apiService.getAllPermissions();
      _allPermissions.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error fetching all permissions: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createRole(String nombre) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newRole = await _apiService.createRole({'nombre': nombre});
      _roles.add(newRole);
      _roles.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRole(String id, String nombre) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedRole = await _apiService.updateRole(id, {'nombre': nombre});
      final index = _roles.indexWhere((rol) => rol.id == id);
      if (index != -1) {
        _roles[index] = updatedRole;
        _roles.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRole(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteRole(id);
      _roles.removeWhere((rol) => rol.id == id);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRolePermissions(String roleId, List<String> permissionIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedRole = await _apiService.updateRolePermissions(roleId, permissionIds);
      final index = _roles.indexWhere((rol) => rol.id == roleId);
      if (index != -1) {
        _roles[index] = updatedRole; // Replace with the role that has updated permissions
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to get a role by its ID
  Rol? getRoleById(String id) {
    try {
      return _roles.firstWhere((rol) => rol.id == id);
    } catch (e) {
      return null;
    }
  }
}
