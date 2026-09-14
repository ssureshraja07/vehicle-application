import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../../core/network/api_constants.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final http.Client _client;
  ProfileRepositoryImpl({http.Client? client}) : _client = client ?? http.Client();

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  @override
  Future<ProfileEntity> getProfile() async {
    final token = await _token();
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profile}');
    final resp = await _client.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final entity = ProfileEntity.fromJson(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profile_completed', entity.profileCompleted);
      return entity;
    } else {
      throw Exception('Failed to load profile (${resp.statusCode})');
    }
  }

  @override
  Future<ProfileEntity> updateProfile({
    required String name,
    required int age,
    required String role,
    required String city,
    File? profileImage,
  }) async {
    final token = await _token();
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profile}');
    final request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = name
      ..fields['age'] = age.toString()
      ..fields['role'] = role
      ..fields['city'] = city;

    if (profileImage != null) {
      request.files.add(
          await http.MultipartFile.fromPath('profileImage', profileImage.path));
    }

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final entity = ProfileEntity.fromJson(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profile_completed', entity.profileCompleted);
      return entity;
    } else {
      throw Exception('Failed to update profile (${resp.statusCode})');
    }
  }
}
