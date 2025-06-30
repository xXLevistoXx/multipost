import 'package:multipost/domain/repositories/auth_repository.dart';

class DeletePost {
  final AuthRepository repository;

  DeletePost(this.repository);

  Future<void> call(String postId) async {
    await repository.deletePost(postId);
  }
}