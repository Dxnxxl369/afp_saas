// lib/providers/empleado_provider.dart
import 'package:flutter/foundation.dart';
import '../models/empleado.dart';
import '../services/api_service.dart';
import 'provider_state.dart';

class EmpleadoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Empleado> _empleados = [];
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';

  List<Empleado> get empleados => _empleados;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  
  Future<void> fetchEmpleados() async {
    if (_loadingState == LoadingState.loading) return;
    _loadingState = LoadingState.loading;
    
    try {
      _empleados = await _apiService.getEmpleados();
      _loadingState = LoadingState.success;
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = e.toString();
      debugPrint("EmpleadoProvider Error: $_errorMessage");
    }
    notifyListeners();
  }
}
