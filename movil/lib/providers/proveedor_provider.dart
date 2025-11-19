// lib/providers/proveedor_provider.dart
import 'package:flutter/foundation.dart';
import '../models/proveedor.dart';
import '../services/api_service.dart';
import 'provider_state.dart';

class ProveedorProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Proveedor> _proveedores = [];
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';

  List<Proveedor> get proveedores => _proveedores;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;

  Future<void> fetchProveedores() async {
    if (_loadingState == LoadingState.loading) return;
    _loadingState = LoadingState.loading;
    notifyListeners();
    
    try {
      _proveedores = await _apiService.getProveedores();
      _loadingState = LoadingState.success;
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = e.toString();
      debugPrint("ProveedorProvider Error: $_errorMessage");
    }
    notifyListeners();
  }

  Future<bool> createProveedor(Map<String, dynamic> data) async {
    _loadingState = LoadingState.loading;
    notifyListeners();
    try {
      final nuevoProveedor = await _apiService.createProveedor(data);
      _proveedores.add(nuevoProveedor);
      _loadingState = LoadingState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _loadingState = LoadingState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProveedor(String id, Map<String, dynamic> data) async {
    _loadingState = LoadingState.loading;
    notifyListeners();
    try {
      final proveedorActualizado = await _apiService.updateProveedor(id, data);
      final index = _proveedores.indexWhere((p) => p.id == id);
      if (index != -1) {
        _proveedores[index] = proveedorActualizado;
      }
      _loadingState = LoadingState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _loadingState = LoadingState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProveedor(String id) async {
    _loadingState = LoadingState.loading;
    notifyListeners();
    try {
      await _apiService.deleteProveedor(id);
      _proveedores.removeWhere((p) => p.id == id);
      _loadingState = LoadingState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _loadingState = LoadingState.error;
      notifyListeners();
      return false;
    }
  }
}
