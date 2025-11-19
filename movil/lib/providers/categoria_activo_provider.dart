// lib/providers/categoria_activo_provider.dart
import 'package:flutter/foundation.dart';
import '../models/categoria_activo.dart';
import '../services/api_service.dart';
import 'provider_state.dart';

class CategoriaActivoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CategoriaActivo> _categorias = [];
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';

  List<CategoriaActivo> get categorias => _categorias;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;

  Future<void> fetchCategoriasActivo() async {
    if (_loadingState == LoadingState.loading) return;
    _loadingState = LoadingState.loading;
    notifyListeners();
    
    try {
      _categorias = await _apiService.getCategoriasActivo();
      _loadingState = LoadingState.success;
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = e.toString();
      debugPrint("CategoriaActivoProvider Error: $_errorMessage");
    }
    notifyListeners();
  }

  Future<bool> createCategoriaActivo(Map<String, dynamic> data) async {
    _loadingState = LoadingState.loading;
    notifyListeners();
    try {
      final nuevaCategoria = await _apiService.createCategoriaActivo(data);
      _categorias.add(nuevaCategoria);
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

  Future<bool> updateCategoriaActivo(String id, Map<String, dynamic> data) async {
    _loadingState = LoadingState.loading;
    notifyListeners();
    try {
      final categoriaActualizada = await _apiService.updateCategoriaActivo(id, data);
      final index = _categorias.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categorias[index] = categoriaActualizada;
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

  Future<bool> deleteCategoriaActivo(String id) async {
    _loadingState = LoadingState.loading;
    notifyListeners();
    try {
      await _apiService.deleteCategoriaActivo(id);
      _categorias.removeWhere((c) => c.id == id);
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
