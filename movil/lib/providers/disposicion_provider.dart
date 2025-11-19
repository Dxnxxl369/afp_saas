// lib/providers/disposicion_provider.dart
import 'package:flutter/foundation.dart';
import '../models/disposicion.dart';
import '../services/api_service.dart';
import 'provider_state.dart';

class DisposicionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Disposicion> _disposiciones = [];
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';

  List<Disposicion> get disposiciones => _disposiciones;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  
  Future<void> fetchDisposiciones() async {
    if (_loadingState == LoadingState.loading) return;
    _loadingState = LoadingState.loading;
    
    try {
      _disposiciones = await _apiService.getDisposiciones();
      _loadingState = LoadingState.success;
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = e.toString();
      debugPrint("DisposicionProvider Error: $_errorMessage");
    }
    notifyListeners();
  }

  Future<bool> createDisposicion(Map<String, dynamic> data) async {
    try {
      final nuevaDisposicion = await _apiService.createDisposicion(data);
      _disposiciones.add(nuevaDisposicion);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDisposicion(String id, Map<String, dynamic> data) async {
     try {
      final disposicionActualizada = await _apiService.updateDisposicion(id, data);
      final index = _disposiciones.indexWhere((d) => d.id == id);
      if (index != -1) {
        _disposiciones[index] = disposicionActualizada;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDisposicion(String id) async {
     try {
      await _apiService.deleteDisposicion(id);
      _disposiciones.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
