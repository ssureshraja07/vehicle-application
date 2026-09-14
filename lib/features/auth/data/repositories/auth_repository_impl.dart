import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_response.dart';
import '../../../../core/network/api_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  final http.Client client;

  AuthRepositoryImpl({http.Client? client}) : client = client ?? http.Client();

  // ──────────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────────

  Future<void> _saveTokens(AuthResponse resp) async {
    final prefs = await SharedPreferences.getInstance();
    if (resp.accessToken != null) {
      await prefs.setString('access_token', resp.accessToken!);
    }
    if (resp.refreshToken != null) {
      await prefs.setString('refresh_token', resp.refreshToken!);
    }
    if (resp.userId != null) {
      await prefs.setInt('user_id', resp.userId!);
    }
    if (resp.status != null) {
      await prefs.setString('auth_status', resp.status!);
    }
  }

  Map<String, String> _jsonHeaders() => {'Content-Type': 'application/json'};

  // ──────────────────────────────────────────────────────────────
  // SEND OTP
  // ──────────────────────────────────────────────────────────────

  @override
  Future<void> sendOtp(String phoneNumber) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.sendOtp}');
    final response = await client
        .post(
          url,
          headers: _jsonHeaders(),
          body: json.encode({'phoneNumber': phoneNumber}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final body = _tryDecodeBody(response.body);
      throw Exception(body['message'] ?? 'Failed to send OTP (${response.statusCode})');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // VERIFY OTP
  // ──────────────────────────────────────────────────────────────

  @override
  Future<AuthResponse> verifyOtp(String phoneNumber, String otp) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyOtp}');
      final response = await client
          .post(
            url,
            headers: _jsonHeaders(),
            body: json.encode({'phoneNumber': phoneNumber, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final auth = AuthResponse.fromJson(data);
        await _saveTokens(auth);
        return auth;
      } else {
        final body = _tryDecodeBody(response.body);
        return AuthResponse.error(
            body['message'] ?? 'Invalid OTP (${response.statusCode})');
      }
    } catch (e) {
      return AuthResponse.error(_connectionError(e));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // REFRESH TOKEN
  // ──────────────────────────────────────────────────────────────

  @override
  Future<AuthResponse> refreshAccessToken(String refreshToken) async {
    try {
      final url =
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshToken}');
      final response = await client
          .post(
            url,
            headers: _jsonHeaders(),
            body: json.encode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final auth = AuthResponse.fromJson(data);
        await _saveTokens(auth);
        return auth;
      } else {
        return AuthResponse.error('Session expired. Please log in again.');
      }
    } catch (e) {
      return AuthResponse.error(_connectionError(e));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // LOGOUT
  // ──────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshTok = prefs.getString('refresh_token');

    if (refreshTok != null && refreshTok.isNotEmpty) {
      try {
        final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logout}');
        await client
            .post(
              url,
              headers: _jsonHeaders(),
              body: json.encode({'refreshToken': refreshTok}),
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Proceed with local logout even if backend call fails
      }
    }

    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('auth_status');
    await prefs.remove('profile_completed');
  }

  // ──────────────────────────────────────────────────────────────
  // PRIVATE UTILITIES
  // ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _tryDecodeBody(String body) {
    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String _connectionError(Object e) {
    final msg = e.toString();
    if (msg.contains('TimeoutException') || msg.contains('timeout')) {
      return 'Connection timed out. Is the server running?';
    }
    return 'Connection failed: $msg';
  }
}

