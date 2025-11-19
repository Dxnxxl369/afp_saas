// lib/providers/revalorizacion_provider.dart
import 'package:flutter/foundation.dart';
import '../models/revalorizacion.dart';
import '../services/api_service.dart';
import 'provider_state.dart';

class RevalorizacionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Revalorizacion> _historial = [];
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';

  List<Revalorizacion> get historial => _historial;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;

  Future<void> fetchRevalorizaciones(String activoId) async {
    if (activoId.isEmpty) {
      _historial = [];
      notifyListeners();
      return;
    }
    _loadingState = LoadingState.loading;
    notifyListeners();
    
    try {
      _historial = await _apiService.getRevalorizaciones(activoId);
      _loadingState = LoadingState.success;
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = e.toString();
      debugPrint("RevalorizacionProvider Error: $_errorMessage");
    }
    notifyListeners();
  }

  Future<bool> ejecutarRevalorizacion(Map<String, dynamic> data) async {
    try {
      await _apiService.ejecutarRevalorizacion(data);
      // After execution, refresh the history
      await fetchRevalorizaciones(data['activo_id']);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
