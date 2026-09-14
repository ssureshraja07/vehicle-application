import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/driver_entity.dart';
import '../../domain/repositories/driver_repository.dart';
import '../../../../core/network/api_constants.dart';

class DriverRepositoryImpl implements DriverRepository {
  final http.Client _client;
  DriverRepositoryImpl({http.Client? client}) : _client = client ?? http.Client();

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  String _driverUrl(int vehicleId) =>
      '${ApiConstants.baseUrl}${ApiConstants.vehicles}/$vehicleId/driver';

  @override
  Future<DriverEntity> addDriver({
    required int vehicleId,
    required String driverName,
    required int driverAge,
    required String driverCity,
  }) async {
    final token = await _token();
    final resp = await _client
        .post(Uri.parse(_driverUrl(vehicleId)),
            headers: _headers(token),
            body: json.encode({
              'driverName': driverName,
              'driverAge': driverAge,
              'driverCity': driverCity,
            }))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return DriverEntity.fromJson(json.decode(resp.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to add driver (${resp.statusCode})');
  }

  @override
  Future<DriverEntity> getDriver(int vehicleId) async {
    final token = await _token();
    final resp = await _client
        .get(Uri.parse(_driverUrl(vehicleId)), headers: _headers(token))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      return DriverEntity.fromJson(json.decode(resp.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to get driver (${resp.statusCode})');
  }

  @override
  Future<DriverEntity> updateDriver({
    required int vehicleId,
    required String driverName,
    required int driverAge,
    required String driverCity,
  }) async {
    final token = await _token();
    final resp = await _client
        .put(Uri.parse(_driverUrl(vehicleId)),
            headers: _headers(token),
            body: json.encode({
              'driverName': driverName,
              'driverAge': driverAge,
              'driverCity': driverCity,
            }))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      return DriverEntity.fromJson(json.decode(resp.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to update driver (${resp.statusCode})');
  }

  @override
  Future<void> deleteDriver(int vehicleId) async {
    final token = await _token();
    final resp = await _client
        .delete(Uri.parse(_driverUrl(vehicleId)), headers: _headers(token))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Failed to delete driver (${resp.statusCode})');
    }
  }
}
