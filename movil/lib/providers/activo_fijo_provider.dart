// lib/providers/activo_fijo_provider.dart
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart'; // Importar XFile
import '../services/api_service.dart';
import '../models/activo_fijo.dart';
import 'provider_state.dart';

class ActivoFijoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ActivoFijo> _activos = [];
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';

  List<ActivoFijo> get activos => _activos;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;

  Future<void> fetchActivos() async {
    if (_loadingState == LoadingState.loading) return;
    _loadingState = LoadingState.loading;
    notifyListeners();

    try {
      _activos = await _apiService.getActivos();
      _loadingState = LoadingState.success;
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = e.toString();
      debugPrint("ActivoFijoProvider Error: $_errorMessage");
    } finally {
      notifyListeners();
    }
  }

  Future<bool> createActivo(Map<String, dynamic> data, {XFile? fotoActivo}) async {
    _loadingState = LoadingState.loading;
    notifyListeners();
    try {
      final nuevoActivo = await _apiService.createActivo(data, fotoActivo: fotoActivo);
      _activos.add(nuevoActivo);
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

  Future<bool> updateActivo(String id, Map<String, dynamic> data, {XFile? fotoActivo, bool deleteExistingPhoto = false}) async {
    _loadingState = LoadingState.loading;
    notifyListeners();
    try {
      final activoActualizado = await _apiService.updateActivo(id, data, fotoActivo: fotoActivo, deleteExistingPhoto: deleteExistingPhoto);
      final index = _activos.indexWhere((a) => a.id == id);
      if (index != -1) {
        _activos[index] = activoActualizado;
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

  Future<bool> deleteActivo(String id) async {
    _loadingState = LoadingState.loading;
    notifyListeners();
    try {
      await _apiService.deleteActivo(id);
      _activos.removeWhere((a) => a.id == id);
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
