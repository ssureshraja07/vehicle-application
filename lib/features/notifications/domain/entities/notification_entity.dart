class NotificationEntity {
  final int id;
  final int recipientUserId;
  final int? requestId;
  final int? vehicleId;
  final String type;
  final String title;
  final String message;
  final bool read;
  final String? createdAt;

  const NotificationEntity({
    required this.id,
    required this.recipientUserId,
    this.requestId,
    this.vehicleId,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    this.createdAt,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      recipientUserId: json['recipientUserId'] is int
          ? json['recipientUserId'] as int
          : int.parse(json['recipientUserId'].toString()),
      requestId: json['requestId'] is int
          ? json['requestId'] as int
          : int.tryParse(json['requestId']?.toString() ?? ''),
      vehicleId: json['vehicleId'] is int
          ? json['vehicleId'] as int
          : int.tryParse(json['vehicleId']?.toString() ?? ''),
      type: json['type']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      createdAt: json['createdAt']?.toString(),
    );
  }

  NotificationEntity copyWith({bool? read}) => NotificationEntity(
        id: id,
        recipientUserId: recipientUserId,
        requestId: requestId,
        vehicleId: vehicleId,
        type: type,
        title: title,
        message: message,
        read: read ?? this.read,
        createdAt: createdAt,
      );
}
