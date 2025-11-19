// lib/providers/depreciacion_provider.dart
import 'package:flutter/foundation.dart';
import '../models/depreciacion.dart';
import '../services/api_service.dart';
import 'provider_state.dart';

class DepreciacionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Depreciacion> _historial = [];
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';

  List<Depreciacion> get historial => _historial;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;

  Future<void> fetchDepreciaciones(String activoId) async {
    if (activoId.isEmpty) {
      _historial = [];
      notifyListeners();
      return;
    }
    _loadingState = LoadingState.loading;
    notifyListeners();
    
    try {
      _historial = await _apiService.getDepreciaciones(activoId);
      _loadingState = LoadingState.success;
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = e.toString();
      debugPrint("DepreciacionProvider Error: $_errorMessage");
    }
    notifyListeners();
  }

  Future<bool> ejecutarDepreciacion(Map<String, dynamic> data) async {
    try {
      await _apiService.ejecutarDepreciacion(data);
      // After execution, refresh the history
      await fetchDepreciaciones(data['activo_id']);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
