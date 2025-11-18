// lib/utils/debounce.dart
import 'dart:async';
import 'package:flutter/foundation.dart'; // Para VoidCallback

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  // La función 'run' solo acepta UN argumento de tipo VoidCallback
  run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  dispose() {
    _timer?.cancel();
  }
}