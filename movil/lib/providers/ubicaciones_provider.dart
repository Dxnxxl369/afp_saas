// lib/providers/ubicaciones_provider.dart
import 'package:flutter/foundation.dart';
import '../models/ubicacion.dart';
import '../services/api_service.dart';
import 'provider_state.dart';

class UbicacionesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Ubicacion> _ubicaciones = [];
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';

  List<Ubicacion> get ubicaciones => _ubicaciones;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  
  Future<void> fetchUbicaciones() async {
    if (_loadingState == LoadingState.loading) return;
    _loadingState = LoadingState.loading;
    
    try {
      _ubicaciones = await _apiService.getUbicaciones();
      _loadingState = LoadingState.success;
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = e.toString();
      debugPrint("UbicacionesProvider Error: $_errorMessage");
    }
    notifyListeners();
  }

  Future<bool> createUbicacion(String nombre, String? direccion, String? detalle) async {
    try {
      final nuevaUbicacion = await _apiService.createUbicacion(nombre, direccion, detalle);
      _ubicaciones.add(nuevaUbicacion);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUbicacion(String id, String nombre, String? direccion, String? detalle) async {
     try {
      final ubicacionActualizada = await _apiService.updateUbicacion(id, nombre, direccion, detalle);
      final index = _ubicaciones.indexWhere((d) => d.id == id);
      if (index != -1) {
        _ubicaciones[index] = ubicacionActualizada;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUbicacion(String id) async {
     try {
      await _apiService.deleteUbicacion(id);
      _ubicaciones.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
