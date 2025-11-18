// lib/providers/mantenimiento_provider.dart
import 'package:flutter/foundation.dart';
import '../models/mantenimiento.dart';
import '../services/api_service.dart';
import 'provider_state.dart';

class MantenimientoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Mantenimiento> _mantenimientos = [];
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';

  List<Mantenimiento> get mantenimientos => _mantenimientos;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  
  Future<void> fetchMantenimientos() async {
    if (_loadingState == LoadingState.loading) return;
    _loadingState = LoadingState.loading;
    
    try {
      _mantenimientos = await _apiService.getMantenimientos();
      _loadingState = LoadingState.success;
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = e.toString();
      debugPrint("MantenimientoProvider Error: $_errorMessage");
    }
    notifyListeners();
  }

  Future<bool> createMantenimiento(Map<String, dynamic> data) async {
    try {
      final nuevoMantenimiento = await _apiService.createMantenimiento(data);
      _mantenimientos.add(nuevoMantenimiento);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMantenimiento(String id, Map<String, dynamic> data) async {
     try {
      final mantenimientoActualizado = await _apiService.updateMantenimiento(id, data);
      final index = _mantenimientos.indexWhere((d) => d.id == id);
      if (index != -1) {
        _mantenimientos[index] = mantenimientoActualizado;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMantenimiento(String id) async {
     try {
      await _apiService.deleteMantenimiento(id);
      _mantenimientos.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
