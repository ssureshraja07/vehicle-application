import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_search_repository.dart';
import '../../../../core/network/api_constants.dart';

class UserSearchRepositoryImpl implements UserSearchRepository {
  final http.Client _client;

  UserSearchRepositoryImpl({http.Client? client})
      : _client = client ?? http.Client();

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  Map<String, String> _authHeader(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// GET /api/v1/users?role=OWNER|DRIVER|MECHANIC
  @override
  Future<List<UserEntity>> getUsersByRole(String role, {String city = 'ALL'}) async {
    final token = await _token();
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/v1/users?role=$role');
    final resp = await _client
        .get(uri, headers: _authHeader(token))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final list = json.decode(resp.body) as List<dynamic>;
      return list
          .map((e) => UserEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load users (${resp.statusCode})');
  }
}
