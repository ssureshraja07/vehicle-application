import '../entities/driver_entity.dart';

abstract class DriverRepository {
  Future<DriverEntity> addDriver({
    required int vehicleId,
    required String driverName,
    required int driverAge,
    required String driverCity,
  });

  Future<DriverEntity> getDriver(int vehicleId);

  Future<DriverEntity> updateDriver({
    required int vehicleId,
    required String driverName,
    required int driverAge,
    required String driverCity,
  });

  Future<void> deleteDriver(int vehicleId);
}
