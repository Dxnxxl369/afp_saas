// lib/utils/helpers.dart

String getInitials(String? fullName) {
  if (fullName == null || fullName.isEmpty) {
    return '?';
  }
  
  List<String> names = fullName.trim().split(' ');
  names.removeWhere((element) => element.isEmpty); // Eliminar espacios extra

  if (names.isEmpty) {
    return '?';
  }

  String initials = names[0][0];
  if (names.length > 1) {
    initials += names.last[0];
  }
  
  return initials.toUpperCase();
}

// Helper para extraer el ID de una URL de detalle
String? extractIdFromUrl(String url) {
  final uri = Uri.parse(url);
  final segments = uri.pathSegments;
  // Asumimos que la URL es del tipo /app/modulo/id
  // y que el ID es el último segmento
  if (segments.isNotEmpty && segments.length > 2) { 
    return segments.last;
  }
  return null;
}
