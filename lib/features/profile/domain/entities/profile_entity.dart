class ProfileEntity {
  final int id;
  final String phoneNumber;
  final String? name;
  final int? age;
  final String? role;   // OWNER | DRIVER | MECHANIC
  final String? city;
  final String? profileImage;
  final bool profileCompleted;

  const ProfileEntity({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.age,
    this.role,
    this.city,
    this.profileImage,
    required this.profileCompleted,
  });

  factory ProfileEntity.fromJson(Map<String, dynamic> json) {
    return ProfileEntity(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      phoneNumber: json['phoneNumber'] ?? '',
      name: json['name'],
      age: json['age'],
      role: json['role']?.toString(),
      city: json['city'],
      profileImage: json['profileImage'],
      profileCompleted: json['profileCompleted'] ?? false,
    );
  }
}
