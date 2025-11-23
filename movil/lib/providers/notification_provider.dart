// movil/lib/providers/notification_provider.dart
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/notification.dart' as app_notification;
import 'package:provider/provider.dart'; // Needed for Provider.of in main.dart

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService;
  List<app_notification.Notification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<app_notification.Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  NotificationProvider(this._apiService); // Constructor receives ApiService

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _apiService.getNotifications();
      _unreadCount = _notifications.where((n) => !n.leido).length;
      debugPrint("Notifications fetched: ${_notifications.length}, Unread: $_unreadCount");
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error fetching notifications: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await _apiService.getUnreadNotificationsCount();
      debugPrint("Unread count fetched: $_unreadCount");
    } catch (e) {
      debugPrint("Error fetching unread count: $e");
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || _notifications[index].leido) return; // No hacer nada si no se encuentra o ya está leída

    try {
      await _apiService.markNotificationAsRead(notificationId);
      // Crear una nueva lista con el elemento actualizado de forma inmutable
      _notifications = [
        for (int i = 0; i < _notifications.length; i++)
          if (i == index)
            _notifications[i].copyWith(leido: true)
          else
            _notifications[i],
      ];
      _unreadCount--;
      notifyListeners();
      debugPrint("Notification $notificationId marked as read.");
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error marking notification $notificationId as read: $_errorMessage");
      // No re-lanzar el error para no romper la UI
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await _apiService.markAllNotificationsAsRead();
      // Crear una nueva lista con TODOS los elementos marcados como leídos
      _notifications = _notifications.map((n) => n.copyWith(leido: true)).toList();
      _unreadCount = 0;
      notifyListeners();
      debugPrint("All notifications marked as read.");
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error marking all notifications as read: $_errorMessage");
      // No re-lanzar el error para no romper la UI
    }
  }

  // A method to refresh all data (useful after a change or for periodic updates)
  Future<void> refresh() async {
    await fetchNotifications();
    // No need to call fetchUnreadCount separately as fetchNotifications updates _unreadCount
  }
}
