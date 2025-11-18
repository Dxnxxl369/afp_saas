// lib/services/api_service.dart

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart'; // (Asegúrate que este archivo exista con tu IP)
import '../models/departamento.dart';
import '../models/periodo_presupuestario.dart';
import '../models/partida_presupuestaria.dart';
import '../models/solicitud_compra.dart';
import '../models/orden_compra.dart';
import '../models/activo_fijo.dart';

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

  // --- 5. Presupuestos: Periodos ---
  Future<List<PeriodoPresupuestario>> getPeriodos() async {
    try {
      final response = await _dio.get('/periodos-presupuestarios/');
      final data = response.data;
      List<dynamic> dataList = (data is Map && data.containsKey('results'))
          ? data['results'] as List
          : data as List;
      return dataList.map((json) => PeriodoPresupuestario.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar periodos: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<PeriodoPresupuestario> createPeriodo(Map<String, dynamic> periodoData) async {
    try {
      final response = await _dio.post('/periodos-presupuestarios/', data: periodoData);
      return PeriodoPresupuestario.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear periodo: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<PeriodoPresupuestario> updatePeriodo(String id, Map<String, dynamic> periodoData) async {
    try {
      final response = await _dio.patch('/periodos-presupuestarios/$id/', data: periodoData);
      return PeriodoPresupuestario.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al actualizar periodo: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<void> deletePeriodo(String id) async {
    try {
      await _dio.delete('/periodos-presupuestarios/$id/');
    } on DioException catch (e) {
      throw Exception('Error al eliminar periodo: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  // --- 6. Presupuestos: Partidas ---
  Future<List<PartidaPresupuestaria>> getPartidas(String periodoId) async {
    try {
      // Asumiendo que el API filtra por query param
      final response = await _dio.get('/partidas-presupuestarias/', queryParameters: {'periodo_id': periodoId});
      final data = response.data;
      List<dynamic> dataList = (data is Map && data.containsKey('results'))
          ? data['results'] as List
          : data as List;
      return dataList.map((json) => PartidaPresupuestaria.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar partidas: ${e.response?.data?['detail'] ?? e.message}');
    }
  }
  
  Future<PartidaPresupuestaria> createPartida(Map<String, dynamic> partidaData) async {
    try {
      final response = await _dio.post('/partidas-presupuestarias/', data: partidaData);
      return PartidaPresupuestaria.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear partida: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<PartidaPresupuestaria> updatePartida(String id, Map<String, dynamic> partidaData) async {
    try {
      final response = await _dio.patch('/partidas-presupuestarias/$id/', data: partidaData);
      return PartidaPresupuestaria.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al actualizar partida: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<void> deletePartida(String id) async {
    try {
      await _dio.delete('/partidas-presupuestarias/$id/');
    } on DioException catch (e) {
      throw Exception('Error al eliminar partida: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  // --- 7. Solicitudes de Compra ---
  Future<List<SolicitudCompra>> getSolicitudes() async {
    try {
      final response = await _dio.get('/solicitudes-compra/');
      final data = response.data;
      List<dynamic> dataList = (data is Map && data.containsKey('results'))
          ? data['results'] as List
          : data as List;
      return dataList.map((json) => SolicitudCompra.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar solicitudes: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<SolicitudCompra> createSolicitud(Map<String, dynamic> solicitudData) async {
    try {
      final response = await _dio.post('/solicitudes-compra/', data: solicitudData);
      return SolicitudCompra.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear solicitud: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<SolicitudCompra> aprobarSolicitud(String id) async {
    try {
      final response = await _dio.post('/solicitudes-compra/$id/aprobar/');
      return SolicitudCompra.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al aprobar solicitud: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<SolicitudCompra> rechazarSolicitud(String id, String motivo) async {
    try {
      final response = await _dio.post('/solicitudes-compra/$id/rechazar/', data: {'motivo_rechazo': motivo});
      return SolicitudCompra.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al rechazar solicitud: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  // --- 8. Órdenes de Compra ---
  Future<List<OrdenCompra>> getOrdenes() async {
    try {
      final response = await _dio.get('/ordenes-compra/');
      final data = response.data;
      List<dynamic> dataList = (data is Map && data.containsKey('results'))
          ? data['results'] as List
          : data as List;
      return dataList.map((json) => OrdenCompra.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar órdenes de compra: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<OrdenCompra> recibirOrden(String id, Map<String, dynamic> activoData) async {
    try {
      // La acción 'recibir' probablemente crea el activo y actualiza la orden
      final response = await _dio.post('/ordenes-compra/$id/recibir/', data: activoData);
      return OrdenCompra.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al recibir la orden: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  // --- 9. Activos Fijos ---
  Future<List<ActivoFijo>> getActivos() async {
    try {
      final response = await _dio.get('/activos-fijos/');
      final data = response.data;
      List<dynamic> dataList = (data is Map && data.containsKey('results'))
          ? data['results'] as List
          : data as List;
      return dataList.map((json) => ActivoFijo.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar activos fijos: ${e.response?.data?['detail'] ?? e.message}');
    }
  }
}