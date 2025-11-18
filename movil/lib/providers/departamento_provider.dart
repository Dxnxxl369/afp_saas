// lib/providers/departamento_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/departamento.dart';
import '../services/api_service.dart';

enum LoadingState { idle, loading, success, error }

class DepartamentoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Departamento> _departamentos = [];
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';

  List<Departamento> get departamentos => _departamentos;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  
  Future<void> fetchDepartamentos() async {
    if (_loadingState == LoadingState.loading) return;
    _loadingState = LoadingState.loading;
    // No notificar aquí para evitar saltos de UI, 
    // la pantalla mostrará el loader basado en 'loadingState'
    
    try {
      _departamentos = await _apiService.getDepartamentos();
      _loadingState = LoadingState.success;
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = e.toString();
      debugPrint("DepartamentoProvider Error: $_errorMessage");
    }
    notifyListeners();
  }

  Future<bool> createDepartamento(String nombre, String? descripcion) async {
    try {
      final nuevoDepto = await _apiService.createDepartamento(nombre, descripcion);
      _departamentos.add(nuevoDepto);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDepartamento(String id, String nombre, String? descripcion) async {
     try {
      final deptoActualizado = await _apiService.updateDepartamento(id, nombre, descripcion);
      final index = _departamentos.indexWhere((d) => d.id == id);
      if (index != -1) {
        _departamentos[index] = deptoActualizado;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDepartamento(String id) async {
     try {
      await _apiService.deleteDepartamento(id);
      _departamentos.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}