// lib/services/api_service.dart

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart'; // (Asegúrate que este archivo exista con tu IP)
import '../models/departamento.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio(BaseOptions(baseUrl: apiBaseUrl)) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options); // Continuar
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          debugPrint("ApiService: Token inválido o expirado (401).");
          // TODO: Llamar a authProvider.logout() de forma global
        }
        return handler.next(e); // Continuar con el error
      },
    ));
  }

  // --- 1. Autenticación (se usa desde auth_service) ---
  // (Las funciones de login/register están en auth_service.dart)

  // --- 2. Permisos ---
  Future<Set<String>> getMyPermissions(String token) async {
    // Usamos el token pasado porque el interceptor puede no tenerlo
    // en la primera llamada de login.
    try {
      final response = await _dio.get(
        '/my-permissions/',
        options: Options(headers: {'Authorization': 'Bearer $token'}), // Enviar token manualmente
      );
      final List<dynamic> list = response.data;
      return list.map((item) => item.toString()).toSet();
    } on DioException catch (e) {
      debugPrint("ApiService(Permissions) Error: ${e.response?.data}");
      throw Exception('Error al cargar permisos');
    }
  }

  // --- 3. Preferencias de Tema ---
  Future<Map<String, dynamic>> updateMyThemePreferences(Map<String, dynamic> preferences) async {
    try {
      // El token se añade automáticamente por el interceptor
      final response = await _dio.patch(
        '/me/theme/',
        data: preferences,
      );
      return response.data; // Devuelve las preferencias actualizadas
    } on DioException catch (e) {
      debugPrint("ApiService(Theme) Error: ${e.response?.data}");
      throw Exception('Error al guardar preferencias de tema: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  // --- 4. Departamentos ---
  Future<List<Departamento>> getDepartamentos() async {
    try {
      final response = await _dio.get('/departamentos/');
      final data = response.data;
      List<dynamic> dataList = (data is Map && data.containsKey('results'))
          ? data['results'] as List
          : data as List;
      return dataList.map((json) => Departamento.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar departamentos: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<Departamento> createDepartamento(String nombre, String? descripcion) async {
    try {
      final response = await _dio.post('/departamentos/', data: {
        'nombre': nombre,
        'descripcion': descripcion,
      });
      // TODO: Llamar a logAction (requiere log_service.dart)
      return Departamento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear departamento: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<Departamento> updateDepartamento(String id, String nombre, String? descripcion) async {
    try {
      final response = await _dio.patch('/departamentos/$id/', data: {
        'nombre': nombre,
        'descripcion': descripcion,
      });
      // TODO: Llamar a logAction
      return Departamento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al actualizar departamento: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<void> deleteDepartamento(String id) async {
    try {
      final response = await _dio.delete('/departamentos/$id/');
      if (response.statusCode == 204) {
        // TODO: Llamar a logAction
        return;
      }
      throw Exception('Error al eliminar departamento: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error al eliminar departamento: ${e.response?.data?['detail'] ?? e.message}');
    }
  }
}