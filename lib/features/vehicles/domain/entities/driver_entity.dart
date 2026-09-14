class DriverEntity {
  final int id;
  final int vehicleId;
  final String driverName;
  final int driverAge;
  final String driverCity;

  const DriverEntity({
    required this.id,
    required this.vehicleId,
    required this.driverName,
    required this.driverAge,
    required this.driverCity,
  });

  factory DriverEntity.fromJson(Map<String, dynamic> json) {
    return DriverEntity(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      vehicleId: json['vehicleId'] is int ? json['vehicleId'] as int : int.parse(json['vehicleId'].toString()),
      driverName: json['driverName'] ?? '',
      driverAge: json['driverAge'] is int ? json['driverAge'] as int : int.parse(json['driverAge'].toString()),
      driverCity: json['driverCity'] ?? '',
    );
  }
}
