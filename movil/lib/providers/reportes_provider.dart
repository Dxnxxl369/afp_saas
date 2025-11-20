// movil/lib/providers/reportes_provider.dart
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/reporte_activo.dart';

class ReportesProvider with ChangeNotifier {
  final ApiService _apiService;
  List<ReporteActivo> _reporteData = [];
  List<String> _filters = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReporteActivo> get reporteData => _reporteData;
  List<String> get filters => _filters;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ReportesProvider(this._apiService);

  Future<void> fetchReport() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reporteData = await _apiService.getDynamicReport(_filters);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error fetching dynamic report: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addFilter(String filter) {
    if (!_filters.contains(filter)) {
      _filters.add(filter);
      fetchReport(); // Refetch report with new filters
    }
  }

  void removeFilter(String filter) {
    _filters.remove(filter);
    fetchReport(); // Refetch report with updated filters
  }

  void clearFilters() {
    _filters = [];
    fetchReport(); // Refetch report with no filters
  }
}
