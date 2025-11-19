// lib/providers/estados_provider.dart
import 'package:flutter/foundation.dart';
import '../models/estado.dart';
import '../services/api_service.dart';
import 'provider_state.dart';

class EstadosProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Estado> _estados = [];
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';

  List<Estado> get estados => _estados;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  
  Future<void> fetchEstados() async {
    if (_loadingState == LoadingState.loading) return;
    _loadingState = LoadingState.loading;
    
    try {
      _estados = await _apiService.getEstados();
      _loadingState = LoadingState.success;
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = e.toString();
      debugPrint("EstadosProvider Error: $_errorMessage");
    }
    notifyListeners();
  }

  Future<bool> createEstado(String nombre, String? detalle) async {
    try {
      final data = {'nombre': nombre, 'detalle': detalle};
      final nuevoEstado = await _apiService.createEstado(data);
      _estados.add(nuevoEstado);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEstado(String id, String nombre, String? detalle) async {
     try {
      final data = {'nombre': nombre, 'detalle': detalle};
      final estadoActualizado = await _apiService.updateEstado(id, data);
      final index = _estados.indexWhere((d) => d.id == id);
      if (index != -1) {
        _estados[index] = estadoActualizado;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEstado(String id) async {
     try {
      await _apiService.deleteEstado(id);
      _estados.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
