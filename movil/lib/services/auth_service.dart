// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/constants.dart';

class AuthService {
  // Usamos una instancia separada de Dio SIN interceptor de token,
  // ya que /token/ y /register/ no necesitan token.
  final Dio _dio = Dio(BaseOptions(baseUrl: apiBaseUrl));

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/token/', data: {
        'username': username,
        'password': password,
      });
      return response.data; // Devuelve { "access": "...", "refresh": "..." }
    } on DioException catch (e) {
      debugPrint("AuthService(Login) Error: ${e.response?.data}");
      final errorMsg = e.response?.data?['detail'] ?? 'Error de red o credenciales.';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Un error inesperado ocurrió.');
    }
  }

  // (Aquí iría la función de registro si la necesitas)
}