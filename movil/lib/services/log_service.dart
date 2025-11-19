// lib/services/log_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart'; // We can reuse the same Dio instance if we expose it

// As ApiService is not exposing its Dio instance, we create a new one.
// In a real app, it would be better to have a shared Dio instance.
import '../config/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';


Future<void> logAction(String accion, [Map<String, dynamic>? payload]) async {
  final Dio _dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
   _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));

  final dataToSend = {
    'accion': accion,
    'payload': payload ?? {},
  };

  try {
    debugPrint("Logging action: $dataToSend");
    await _dio.post('/logs/', data: dataToSend);
  } catch (e) {
    debugPrint('Failed to log action: $e');
  }
}
