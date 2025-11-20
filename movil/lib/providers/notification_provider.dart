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
    try {
      await _apiService.markNotificationAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].leido) {
        _notifications[index].leido = true;
        _unreadCount--;
        notifyListeners();
      }
      debugPrint("Notification $notificationId marked as read locally.");
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error marking notification $notificationId as read: $_errorMessage");
      rethrow;
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await _apiService.markAllNotificationsAsRead();
      for (var n in _notifications) {
        n.leido = true;
      }
      _unreadCount = 0;
      notifyListeners();
      debugPrint("All notifications marked as read locally.");
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error marking all notifications as read: $_errorMessage");
      rethrow;
    }
  }

  // A method to refresh all data (useful after a change or for periodic updates)
  Future<void> refresh() async {
    await fetchNotifications();
    // No need to call fetchUnreadCount separately as fetchNotifications updates _unreadCount
  }
}
