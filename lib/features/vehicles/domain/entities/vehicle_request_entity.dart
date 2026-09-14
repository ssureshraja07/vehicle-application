class VehicleRequestEntity {
  final int id;
  final int vehicleId;
  final int requesterUserId;
  final String status; // PENDING | ACCEPTED | REJECTED
  final String? createdAt;

  const VehicleRequestEntity({
    required this.id,
    required this.vehicleId,
    required this.requesterUserId,
    required this.status,
    this.createdAt,
  });

  factory VehicleRequestEntity.fromJson(Map<String, dynamic> json) {
    return VehicleRequestEntity(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      vehicleId: json['vehicleId'] is int ? json['vehicleId'] as int : int.parse(json['vehicleId'].toString()),
      requesterUserId: json['requesterUserId'] is int ? json['requesterUserId'] as int : int.parse(json['requesterUserId'].toString()),
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: json['createdAt']?.toString(),
    );
  }
}
