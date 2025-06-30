import 'package:multipost/domain/repositories/auth_repository.dart';

class VerifyCode {
  final AuthRepository repository;

  VerifyCode(this.repository);

  Future<bool> call(String phone, String code, String? password, String login) async {
    return await repository.verifyCode(phone, code, password, login);
  }
}