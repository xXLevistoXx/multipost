import 'dart:io';
import 'package:multipost/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreatePost {
  final AuthRepository repository;

  CreatePost(this.repository);

  Future<void> call({
    required String phone,
    required List<String> chatUsernames,
    required String title,
    required String description,
    List<File>? images,
    String? scheduleDate,
  }) async {
    // Получаем userId из SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('account_id');
    if (userId == null) {
      throw Exception('User ID not found. Please log in.');
    }

    // Отправка в Telegram через FastAPI
    await repository.createPost(
      phone: phone,
      chatUsernames: chatUsernames,
      title: title,
      description: description,
      images: images,
      scheduleDate: scheduleDate,
    );

    // Сохранение в базу данных через Go-бэкенд
    await repository.savePostToGoBackend(
      userId: userId,
      title: title,
      description: description,
      socialIds: chatUsernames, // Предполагаем, что chatUsernames можно использовать как socialIds
      scheduleDate: scheduleDate,
      images: images,
    );
  }
}