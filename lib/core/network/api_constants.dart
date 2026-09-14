import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // ============================================================
  // CHANGE THIS to your PC's local IP address.
  // Find it by running 'ipconfig' (Windows) or 'ifconfig' (Mac/Linux).
  // Both your phone and PC must be on the same WiFi network.
  // ============================================================
  static final String _serverHost = dotenv.env['SERVER_HOST'] ?? '127.0.0.1';
  static final int _serverPort =
      int.tryParse(dotenv.env['SERVER_PORT'] ?? '8080') ?? 8080;

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:$_serverPort';
    return 'http://$_serverHost:$_serverPort';
  }

  // ──────────────────────────────────────────────────────────────
  // AUTH  /api/v1/auth
  // ──────────────────────────────────────────────────────────────
  static const String sendOtp = '/api/v1/auth/otp/send';
  static const String verifyOtp = '/api/v1/auth/otp/verify';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';

  // ──────────────────────────────────────────────────────────────
  // PROFILE  /api/v1/profile
  // ──────────────────────────────────────────────────────────────
  static const String profile = '/api/v1/profile';

  // ──────────────────────────────────────────────────────────────
  // VEHICLES  /api/v1/vehicles
  // ──────────────────────────────────────────────────────────────
  static const String vehicles = '/api/v1/vehicles';

  // ──────────────────────────────────────────────────────────────
  // VEHICLE REQUESTS  /api/v1/vehicles/{vehicleId}/requests
  // /api/v1/vehicles/requests/{requestId}/accept|reject
  // ──────────────────────────────────────────────────────────────
  // Constructed dynamically in repos.

  // ──────────────────────────────────────────────────────────────
  // NOTIFICATIONS  /api/v1/vehicles/notifications
  // ──────────────────────────────────────────────────────────────
  static const String notifications = '/api/v1/vehicles/notifications';
  static const String unreadCount =
      '/api/v1/vehicles/notifications/unread-count';

  // ──────────────────────────────────────────────────────────────
  // DRIVER POSTS  /api/v1/driver-posts
  // ──────────────────────────────────────────────────────────────
  static const String driverPosts = '/api/v1/driver-posts';

  // ──────────────────────────────────────────────────────────────
  // USERS (role filter)  /api/v1/users
  // ──────────────────────────────────────────────────────────────
  static const String users = '/api/v1/users';
}
