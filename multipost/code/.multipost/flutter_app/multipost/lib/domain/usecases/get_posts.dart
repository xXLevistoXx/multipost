import 'package:multipost/data/models/post_model.dart';
import 'package:multipost/domain/repositories/auth_repository.dart';

class GetPosts {
  final AuthRepository repository;

  GetPosts(this.repository);

  Future<List<PostModel>> call(String userId) async {
    return await repository.getPosts(userId);
  }
}