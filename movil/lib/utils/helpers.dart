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
