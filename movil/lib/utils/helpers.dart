// lib/utils/helpers.dart

String getInitials(String? name) {
  if (name == null || name.isEmpty) return '??';
  final parts = name.split(' ');
  if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  } else if (parts[0].length >= 2) {
    return (parts[0].substring(0, 2)).toUpperCase();
  } else if (parts[0].isNotEmpty) {
    return (parts[0].substring(0, 1)).toUpperCase();
  }
  return '??';
}