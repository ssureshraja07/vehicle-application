class UserEntity {
  final int id;
  final String phoneNumber;
  final String name;
  final int? age;
  final String role;
  final String city;
  final String? profileImage;
  final bool profileCompleted;

  const UserEntity({
    required this.id,
    required this.phoneNumber,
    required this.name,
    this.age,
    required this.role,
    required this.city,
    this.profileImage,
    required this.profileCompleted,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      phoneNumber: json['phoneNumber'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] is int ? json['age'] as int : null,
      role: json['role']?.toString() ?? '',
      city: json['city'] ?? '',
      profileImage: json['profileImage'],
      profileCompleted: json['profileCompleted'] as bool? ?? false,
    );
  }
}
