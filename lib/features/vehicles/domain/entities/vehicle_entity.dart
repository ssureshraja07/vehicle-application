class VehicleEntity {
  final int id;
  final int userId;
  final String vehicleType;
  final String vehicleNumber;
  final String? vehicleImage;

  const VehicleEntity({
    required this.id,
    required this.userId,
    required this.vehicleType,
    required this.vehicleNumber,
    this.vehicleImage,
  });

  factory VehicleEntity.fromJson(Map<String, dynamic> json) {
    return VehicleEntity(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      userId: json['userId'] is int ? json['userId'] as int : int.parse(json['userId'].toString()),
      vehicleType: json['vehicleType']?.toString() ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      vehicleImage: json['vehicleImage'],
    );
  }
}
