// lib/providers/activo_fijo_provider.dart
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/activo_fijo.dart';

class ActivoFijoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ActivoFijo> _activos = [];
  bool _isLoading = false;
  String? _error;

  List<ActivoFijo> get activos => _activos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchActivos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activos = await _apiService.getActivos();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
