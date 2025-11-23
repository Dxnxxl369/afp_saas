// lib/providers/orden_compra_provider.dart
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/orden_compra.dart';

class OrdenCompraProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<OrdenCompra> _ordenes = [];
  bool _isLoading = false;
  String? _error;

  List<OrdenCompra> get ordenes => _ordenes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrdenes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ordenes = await _apiService.getOrdenes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createOrdenCompra(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final nuevaOrden = await _apiService.createOrdenCompra(data);
      _ordenes.insert(0, nuevaOrden);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw Exception('Error al crear la orden de compra: $_error');
    }
  }

  Future<void> recibirOrden(String id, Map<String, dynamic> activoData) async {
    try {
      final updatedOrden = await _apiService.recibirOrden(id, activoData);
      _updateOrdenInList(updatedOrden);
    } catch (e) {
      rethrow;
    }
  }

  void _updateOrdenInList(OrdenCompra orden) {
    final index = _ordenes.indexWhere((o) => o.id == orden.id);
    if (index != -1) {
      _ordenes[index] = orden;
      notifyListeners();
    }
  }
}
