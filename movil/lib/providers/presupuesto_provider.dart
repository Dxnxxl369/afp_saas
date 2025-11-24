// lib/providers/presupuesto_provider.dart
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/periodo_presupuestario.dart';
import '../models/partida_presupuestaria.dart';

class PresupuestoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- State for Periodos ---
  List<PeriodoPresupuestario> _periodos = [];
  bool _isLoadingPeriodos = false;
  String? _errorPeriodos;

  List<PeriodoPresupuestario> get periodos => _periodos;
  bool get isLoadingPeriodos => _isLoadingPeriodos;
  String? get errorPeriodos => _errorPeriodos;

  // --- State for Partidas ---
  List<PartidaPresupuestaria> _partidas = [];
  bool _isLoadingPartidas = false;
  String? _errorPartidas;

  List<PartidaPresupuestaria> get partidas => _partidas;
  bool get isLoadingPartidas => _isLoadingPartidas;
  String? get errorPartidas => _errorPartidas;

  // --- Methods for Periodos ---

  Future<void> fetchPeriodos() async {
    _isLoadingPeriodos = true;
    _errorPeriodos = null;
    notifyListeners();

    try {
      _periodos = await _apiService.getPeriodos();
    } catch (e) {
      _errorPeriodos = e.toString();
    } finally {
      _isLoadingPeriodos = false;
      notifyListeners();
    }
  }

  Future<void> addPeriodo(Map<String, dynamic> periodoData) async {
    try {
      final newPeriodo = await _apiService.createPeriodo(periodoData);
      _periodos.insert(0, newPeriodo); // Añadir al inicio de la lista
      notifyListeners();
    } catch (e) {
      debugPrint("Error en addPeriodo: $e");
      rethrow; // Lanza el error para que la UI lo maneje
    }
  }

  Future<void> updatePeriodo(String id, Map<String, dynamic> periodoData) async {
    try {
      final updatedPeriodo = await _apiService.updatePeriodo(id, periodoData);
      final index = _periodos.indexWhere((p) => p.id == id);
      if (index != -1) {
        _periodos[index] = updatedPeriodo;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error en updatePeriodo: $e");
      rethrow;
    }
  }

  Future<void> deletePeriodo(String id) async {
    try {
      await _apiService.deletePeriodo(id);
      _periodos.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error en deletePeriodo: $e");
      rethrow;
    }
  }

  // --- Methods for Partidas ---

  Future<void> fetchPartidas(String periodoId, {String? departamentoId}) async {
    _isLoadingPartidas = true;
    _errorPartidas = null;
    notifyListeners();

    try {
      _partidas = await _apiService.getPartidas(periodoId, departamentoId: departamentoId);
    } catch (e) {
      _errorPartidas = e.toString();
    } finally {
      _isLoadingPartidas = false;
      notifyListeners();
    }
  }
  
  // Los métodos para CUD de partidas se pueden añadir de forma similar si son necesarios
}
