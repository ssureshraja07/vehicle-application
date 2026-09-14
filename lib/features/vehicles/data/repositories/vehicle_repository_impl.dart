import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/vehicle_request_entity.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../../../../core/network/api_constants.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final http.Client _client;
  VehicleRepositoryImpl({http.Client? client}) : _client = client ?? http.Client();

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  Map<String, String> _authHeader(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ──────────────────────────────────────────────────────────────────
  // CREATE VEHICLE  POST /api/v1/vehicles  (multipart)
  // ──────────────────────────────────────────────────────────────────
  @override
  Future<VehicleEntity> createVehicle({
    required String vehicleType,
    required String vehicleNumber,
    File? vehicleImage,
  }) async {
    final token = await _token();
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vehicles}');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['vehicleType'] = vehicleType
      ..fields['vehicleNumber'] = vehicleNumber;

    if (vehicleImage != null) {
      request.files.add(
          await http.MultipartFile.fromPath('vehicleImage', vehicleImage.path));
    }

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return VehicleEntity.fromJson(
          json.decode(resp.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to create vehicle (${resp.statusCode})');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // GET MY VEHICLES  GET /api/v1/vehicles
  // ──────────────────────────────────────────────────────────────────
  @override
  Future<List<VehicleEntity>> getMyVehicles() async {
    final token = await _token();
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vehicles}');
    final resp = await _client
        .get(uri, headers: _authHeader(token))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final list = json.decode(resp.body) as List<dynamic>;
      return list
          .map((e) => VehicleEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load vehicles (${resp.statusCode})');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // UPDATE VEHICLE  PUT /api/v1/vehicles/{vehicleId}
  // ──────────────────────────────────────────────────────────────────
  @override
  Future<VehicleEntity> updateVehicle({
    required int vehicleId,
    required String vehicleType,
    required String vehicleNumber,
    String? vehicleImage,
  }) async {
    final token = await _token();
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.vehicles}/$vehicleId');
    final body = <String, dynamic>{
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
    };
    if (vehicleImage != null) body['vehicleImage'] = vehicleImage;

    final resp = await _client
        .put(uri,
            headers: _authHeader(token), body: json.encode(body))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      return VehicleEntity.fromJson(
          json.decode(resp.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to update vehicle (${resp.statusCode})');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // DELETE VEHICLE  DELETE /api/v1/vehicles/{vehicleId}
  // ──────────────────────────────────────────────────────────────────
  @override
  Future<void> deleteVehicle(int vehicleId) async {
    final token = await _token();
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.vehicles}/$vehicleId');
    final resp = await _client
        .delete(uri, headers: _authHeader(token))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Failed to delete vehicle (${resp.statusCode})');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // SEND REQUEST  POST /api/v1/vehicles/{vehicleId}/requests
  // ──────────────────────────────────────────────────────────────────
  @override
  Future<VehicleRequestEntity> sendRequest(int vehicleId) async {
    final token = await _token();
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.vehicles}/$vehicleId/requests');
    final resp = await _client
        .post(uri, headers: _authHeader(token))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return VehicleRequestEntity.fromJson(
          json.decode(resp.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to send request (${resp.statusCode})');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // GET REQUESTS  GET /api/v1/vehicles/{vehicleId}/requests
  // ──────────────────────────────────────────────────────────────────
  @override
  Future<List<VehicleRequestEntity>> getRequests(int vehicleId) async {
    final token = await _token();
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.vehicles}/$vehicleId/requests');
    final resp = await _client
        .get(uri, headers: _authHeader(token))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      final list = json.decode(resp.body) as List<dynamic>;
      return list
          .map((e) => VehicleRequestEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to get requests (${resp.statusCode})');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // ACCEPT REQUEST  PATCH /api/v1/vehicles/requests/{requestId}/accept
  // ──────────────────────────────────────────────────────────────────
  @override
  Future<VehicleRequestEntity> acceptRequest(int requestId) async {
    final token = await _token();
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.vehicles}/requests/$requestId/accept');
    final resp = await _client
        .patch(uri, headers: _authHeader(token))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      return VehicleRequestEntity.fromJson(
          json.decode(resp.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to accept request (${resp.statusCode})');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // REJECT REQUEST  PATCH /api/v1/vehicles/requests/{requestId}/reject
  // ──────────────────────────────────────────────────────────────────
  @override
  Future<VehicleRequestEntity> rejectRequest(int requestId) async {
    final token = await _token();
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.vehicles}/requests/$requestId/reject');
    final resp = await _client
        .patch(uri, headers: _authHeader(token))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      return VehicleRequestEntity.fromJson(
          json.decode(resp.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to reject request (${resp.statusCode})');
    }
  }
}
