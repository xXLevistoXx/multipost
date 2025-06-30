import 'package:multipost/domain/repositories/auth_repository.dart';

class RequestCode {
  final AuthRepository repository;

  RequestCode(this.repository);

  Future<bool> call(String phone, String login) async {
    return await repository.requestCode(phone, login);
  }
}