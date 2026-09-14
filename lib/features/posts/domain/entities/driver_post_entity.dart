class DriverPostEntity {
  final int postId;
  final int vehicleId;
  final int ownerId;
  final String ownerName;
  final String ownerCity;
  final String vehicleType;
  final String vehicleNumber;
  final String? vehicleImage;
  final String? createdAt;

  const DriverPostEntity({
    required this.postId,
    required this.vehicleId,
    required this.ownerId,
    required this.ownerName,
    required this.ownerCity,
    required this.vehicleType,
    required this.vehicleNumber,
    this.vehicleImage,
    this.createdAt,
  });

  factory DriverPostEntity.fromJson(Map<String, dynamic> json) {
    return DriverPostEntity(
      postId: json['postId'] is int
          ? json['postId'] as int
          : int.parse(json['postId'].toString()),
      vehicleId: json['vehicleId'] is int
          ? json['vehicleId'] as int
          : int.parse(json['vehicleId'].toString()),
      ownerId: json['ownerId'] is int
          ? json['ownerId'] as int
          : int.parse(json['ownerId'].toString()),
      ownerName: json['ownerName'] ?? '',
      ownerCity: json['ownerCity'] ?? '',
      vehicleType: json['vehicleType']?.toString() ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      vehicleImage: json['vehicleImage'],
      createdAt: json['createdAt']?.toString(),
    );
  }
}
