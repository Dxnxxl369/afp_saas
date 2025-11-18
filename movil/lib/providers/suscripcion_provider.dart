// lib/providers/suscripcion_provider.dart
import 'package:flutter/foundation.dart';
import '../models/suscripcion.dart';
import '../services/api_service.dart';
import 'provider_state.dart';

class SuscripcionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Suscripcion? _suscripcion;
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';

  Suscripcion? get suscripcion => _suscripcion;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  
  Future<void> fetchSuscripcion() async {
    if (_loadingState == LoadingState.loading) return;
    _loadingState = LoadingState.loading;
    
    try {
      _suscripcion = await _apiService.getSuscripcion();
      _loadingState = LoadingState.success;
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = e.toString();
      debugPrint("SuscripcionProvider Error: $_errorMessage");
    }
    notifyListeners();
  }
}
