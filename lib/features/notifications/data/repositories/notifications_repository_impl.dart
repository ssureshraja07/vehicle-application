import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../../../core/network/api_constants.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final http.Client _client;
  NotificationsRepositoryImpl({http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    final headers = await _headers();
    final uri =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}');
    final resp = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final list = json.decode(resp.body) as List<dynamic>;
      return list
          .map((e) =>
              NotificationEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load notifications (${resp.statusCode})');
  }

  @override
  Future<NotificationEntity> markAsRead(int notificationId) async {
    final headers = await _headers();
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.notifications}/$notificationId/read');
    final resp = await _client
        .patch(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      return NotificationEntity.fromJson(
          json.decode(resp.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to mark notification read (${resp.statusCode})');
  }

  @override
  Future<int> getUnreadCount() async {
    final headers = await _headers();
    final uri =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.unreadCount}');
    final resp = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      return int.tryParse(resp.body.trim()) ?? 0;
    }
    return 0;
  }
}
