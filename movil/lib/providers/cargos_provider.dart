// lib/providers/cargos_provider.dart
import 'package:flutter/foundation.dart';
import '../models/cargo.dart';
import '../services/api_service.dart';
import 'provider_state.dart';

class CargosProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Cargo> _cargos = [];
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';

  List<Cargo> get cargos => _cargos;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  
  Future<void> fetchCargos() async {
    if (_loadingState == LoadingState.loading) return;
    _loadingState = LoadingState.loading;
    
    try {
      _cargos = await _apiService.getCargos();
      _loadingState = LoadingState.success;
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = e.toString();
      debugPrint("CargosProvider Error: $_errorMessage");
    }
    notifyListeners();
  }

  Future<bool> createCargo(String nombre, String? descripcion) async {
    try {
      final nuevoCargo = await _apiService.createCargo(nombre, descripcion);
      _cargos.add(nuevoCargo);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCargo(String id, String nombre, String? descripcion) async {
     try {
      final cargoActualizado = await _apiService.updateCargo(id, nombre, descripcion);
      final index = _cargos.indexWhere((d) => d.id == id);
      if (index != -1) {
        _cargos[index] = cargoActualizado;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCargo(String id) async {
     try {
      await _apiService.deleteCargo(id);
      _cargos.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
