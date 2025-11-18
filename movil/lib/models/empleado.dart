// lib/models/empleado.dart

// Modelo completo para listas y detalles de empleados
class Empleado {
  final String id;
  final String ci;
  final String nombreCompleto;
  final String email;
  final String? cargoNombre;
  final String? departamentoNombre;

  Empleado({
    required this.id,
    required this.ci,
    required this.nombreCompleto,
    required this.email,
    this.cargoNombre,
    this.departamentoNombre,
  });

  factory Empleado.fromJson(Map<String, dynamic> json) {
    final user = json['usuario'] ?? {};
    final firstName = user['first_name'] ?? '';
    final lastName = json['apellido_p'] ?? '';
    
    return Empleado(
      id: json['id'],
      ci: json['ci'] ?? '',
      nombreCompleto: '$firstName $lastName'.trim(),
      email: user['email'] ?? '',
      cargoNombre: json['cargo_nombre'],
      departamentoNombre: json['departamento_nombre'],
    );
  }
}


// Modelo simple para usar en dropdowns o vistas anidadas
class EmpleadoSimple {
  final String id;
  final String nombreCompleto;

  EmpleadoSimple({
    required this.id,
    required this.nombreCompleto,
  });

  factory EmpleadoSimple.fromJson(Map<String, dynamic> json) {
    final user = json['usuario'] ?? {};
    final firstName = user['first_name'] ?? '';
    final lastName = json['apellido_p'] ?? '';
    return EmpleadoSimple(
      id: json['id'],
      nombreCompleto: '$firstName $lastName'.trim(),
    );
  }
}