import 'dart:io';
import '../entities/vehicle_entity.dart';
import '../entities/vehicle_request_entity.dart';

abstract class VehicleRepository {
  Future<VehicleEntity> createVehicle({
    required String vehicleType,
    required String vehicleNumber,
    File? vehicleImage,
  });

  Future<List<VehicleEntity>> getMyVehicles();

  Future<VehicleEntity> updateVehicle({
    required int vehicleId,
    required String vehicleType,
    required String vehicleNumber,
    String? vehicleImage,
  });

  Future<void> deleteVehicle(int vehicleId);

  // Requests
  Future<VehicleRequestEntity> sendRequest(int vehicleId);
  Future<List<VehicleRequestEntity>> getRequests(int vehicleId);
  Future<VehicleRequestEntity> acceptRequest(int requestId);
  Future<VehicleRequestEntity> rejectRequest(int requestId);
}
