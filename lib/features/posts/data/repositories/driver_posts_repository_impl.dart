import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/driver_post_entity.dart';
import '../../domain/repositories/driver_posts_repository.dart';
import '../../../../core/network/api_constants.dart';

class DriverPostsRepositoryImpl implements DriverPostsRepository {
  final http.Client _client;
  DriverPostsRepositoryImpl({http.Client? client})
      : _client = client ?? http.Client();

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  Map<String, String> _authHeader(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // GET /api/v1/driver-posts?city=ALL  (requires auth)
  @override
  Future<List<DriverPostEntity>> getDriverPosts({String city = 'ALL'}) async {
    final token = await _token();
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.driverPosts}?city=$city');
    final resp = await _client
        .get(uri, headers: _authHeader(token))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final list = json.decode(resp.body) as List<dynamic>;
      return list
          .map((e) =>
              DriverPostEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load driver posts (${resp.statusCode})');
  }

  // POST /api/v1/driver-posts/{vehicleId}
  @override
  Future<void> postForDriver(int vehicleId) async {
    final token = await _token();
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.driverPosts}/$vehicleId');
    final resp = await _client
        .post(uri, headers: _authHeader(token))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Failed to post for driver (${resp.statusCode})');
    }
  }

  // DELETE /api/v1/driver-posts/{postId}
  @override
  Future<void> deletePost(int postId) async {
    final token = await _token();
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.driverPosts}/$postId');
    final resp = await _client
        .delete(uri, headers: _authHeader(token))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Failed to delete post (${resp.statusCode})');
    }
  }
}
