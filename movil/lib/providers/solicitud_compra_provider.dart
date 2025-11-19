// lib/providers/solicitud_compra_provider.dart
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/solicitud_compra.dart';

class SolicitudCompraProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<SolicitudCompra> _solicitudes = [];
  bool _isLoading = false;
  String? _error;

  List<SolicitudCompra> get solicitudes => _solicitudes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSolicitudes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _solicitudes = await _apiService.getSolicitudes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSolicitud(Map<String, dynamic> solicitudData) async {
    try {
      final newSolicitud = await _apiService.createSolicitud(solicitudData);
      _solicitudes.insert(0, newSolicitud);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> aprobarSolicitud(String id) async {
    try {
      final updatedSolicitud = await _apiService.aprobarSolicitud(id, {});
      _updateSolicitudInList(updatedSolicitud);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rechazarSolicitud(String id, String motivo) async {
    try {
      final updatedSolicitud = await _apiService.rechazarSolicitud(id, {'motivo_rechazo': motivo});
      _updateSolicitudInList(updatedSolicitud);
    } catch (e) {
      rethrow;
    }
  }

  void _updateSolicitudInList(SolicitudCompra solicitud) {
    final index = _solicitudes.indexWhere((s) => s.id == solicitud.id);
    if (index != -1) {
      _solicitudes[index] = solicitud;
      notifyListeners();
    }
  }
}
