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
import '../models/cargo.dart';
import '../models/ubicacion.dart';
import '../models/estado.dart';
import '../models/mantenimiento.dart';
import '../models/empleado.dart';
import '../models/suscripcion.dart';

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

  // --- 5. Cargos ---
  Future<List<Cargo>> getCargos() async {
    try {
      final response = await _dio.get('/cargos/');
      final data = response.data;
      List<dynamic> dataList = (data is Map && data.containsKey('results'))
          ? data['results'] as List
          : data as List;
      return dataList.map((json) => Cargo.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar cargos: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<Cargo> createCargo(String nombre, String? descripcion) async {
    try {
      final response = await _dio.post('/cargos/', data: {
        'nombre': nombre,
        'descripcion': descripcion,
      });
      return Cargo.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear cargo: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<Cargo> updateCargo(String id, String nombre, String? descripcion) async {
    try {
      final response = await _dio.patch('/cargos/$id/', data: {
        'nombre': nombre,
        'descripcion': descripcion,
      });
      return Cargo.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al actualizar cargo: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<void> deleteCargo(String id) async {
    try {
      final response = await _dio.delete('/cargos/$id/');
      if (response.statusCode != 204) {
        throw Exception('Error al eliminar cargo: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error al eliminar cargo: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  // --- 6. Ubicaciones ---
  Future<List<Ubicacion>> getUbicaciones() async {
    try {
      final response = await _dio.get('/ubicaciones/');
      final data = response.data;
      List<dynamic> dataList = (data is Map && data.containsKey('results'))
          ? data['results'] as List
          : data as List;
      return dataList.map((json) => Ubicacion.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar ubicaciones: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<Ubicacion> createUbicacion(String nombre, String? direccion, String? detalle) async {
    try {
      final response = await _dio.post('/ubicaciones/', data: {
        'nombre': nombre,
        'direccion': direccion,
        'detalle': detalle,
      });
      return Ubicacion.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear ubicación: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<Ubicacion> updateUbicacion(String id, String nombre, String? direccion, String? detalle) async {
    try {
      final response = await _dio.patch('/ubicaciones/$id/', data: {
        'nombre': nombre,
        'direccion': direccion,
        'detalle': detalle,
      });
      return Ubicacion.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al actualizar ubicación: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<void> deleteUbicacion(String id) async {
    try {
      final response = await _dio.delete('/ubicaciones/$id/');
      if (response.statusCode != 204) {
        throw Exception('Error al eliminar ubicación: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error al eliminar ubicación: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  // --- 7. Estados ---
  Future<List<Estado>> getEstados() async {
    try {
      final response = await _dio.get('/estados/');
      final data = response.data;
      List<dynamic> dataList = (data is Map && data.containsKey('results'))
          ? data['results'] as List
          : data as List;
      return dataList.map((json) => Estado.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar estados: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<Estado> createEstado(String nombre, String? detalle) async {
    try {
      final response = await _dio.post('/estados/', data: {
        'nombre': nombre,
        'detalle': detalle,
      });
      return Estado.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear estado: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<Estado> updateEstado(String id, String nombre, String? detalle) async {
    try {
      final response = await _dio.patch('/estados/$id/', data: {
        'nombre': nombre,
        'detalle': detalle,
      });
      return Estado.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al actualizar estado: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<void> deleteEstado(String id) async {
    try {
      final response = await _dio.delete('/estados/$id/');
      if (response.statusCode != 204) {
        throw Exception('Error al eliminar estado: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error al eliminar estado: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  // --- 8. Mantenimientos ---
  Future<List<Mantenimiento>> getMantenimientos() async {
    try {
      final response = await _dio.get('/mantenimientos/');
      final data = response.data;
      List<dynamic> dataList = (data is Map && data.containsKey('results'))
          ? data['results'] as List
          : data as List;
      return dataList.map((json) => Mantenimiento.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar mantenimientos: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<Mantenimiento> createMantenimiento(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/mantenimientos/', data: data);
      return Mantenimiento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear mantenimiento: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<Mantenimiento> updateMantenimiento(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/mantenimientos/$id/', data: data);
      return Mantenimiento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al actualizar mantenimiento: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  Future<void> deleteMantenimiento(String id) async {
    try {
      final response = await _dio.delete('/mantenimientos/$id/');
      if (response.statusCode != 204) {
        throw Exception('Error al eliminar mantenimiento: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error al eliminar mantenimiento: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  // --- 9. Empleados ---
  Future<List<Empleado>> getEmpleados() async {
    try {
      final response = await _dio.get('/empleados/');
      final data = response.data;
      List<dynamic> dataList = (data is Map && data.containsKey('results'))
          ? data['results'] as List
          : data as List;
      return dataList.map((json) => Empleado.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar empleados: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  // --- 10. Suscripcion ---
  Future<Suscripcion?> getSuscripcion() async {
    try {
      final response = await _dio.get('/suscripciones/');
      final data = response.data;
      List<dynamic> dataList = (data is Map && data.containsKey('results'))
          ? data['results'] as List
          : data as List;
      if (dataList.isNotEmpty) {
        return Suscripcion.fromJson(dataList.first);
      }
      return null;
    } on DioException catch (e) {
      throw Exception('Error al cargar la suscripción: ${e.response?.data?['detail'] ?? e.message}');
    }
  }

  // --- 11. Presupuestos: Periodos ---
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