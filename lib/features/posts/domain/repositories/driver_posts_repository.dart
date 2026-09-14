import '../entities/driver_post_entity.dart';

abstract class DriverPostsRepository {
  Future<List<DriverPostEntity>> getDriverPosts({String city = 'ALL'});
  Future<void> postForDriver(int vehicleId);
  Future<void> deletePost(int postId);
}
