// lib/providers/dashboard_provider.dart
import 'package:flutter/foundation.dart';
import '../models/dashboard_data.dart';
import '../services/api_service.dart';
import 'provider_state.dart';

class DashboardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  DashboardData? _dashboardData;
  LoadingState _loadingState = LoadingState.idle;
  String _errorMessage = '';

  DashboardData? get dashboardData => _dashboardData;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;

  Future<void> fetchDashboardData() async {
    if (_loadingState == LoadingState.loading) return;
    _loadingState = LoadingState.loading;
    notifyListeners();

    try {
      _dashboardData = await _apiService.getDashboardData();
      _loadingState = LoadingState.success;
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = e.toString();
      debugPrint("DashboardProvider Error: $_errorMessage");
    }
    notifyListeners();
  }
}
