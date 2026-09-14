import '../entities/profile_entity.dart';
import 'dart:io';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile();
  Future<ProfileEntity> updateProfile({
    required String name,
    required int age,
    required String role,
    required String city,
    File? profileImage,
  });
}
