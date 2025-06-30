import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:multipost/core/constants.dart';
import 'package:multipost/data/models/channel_model.dart';
import 'package:multipost/data/models/post_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteDataSource {
  Future<bool> requestCode(String phone, String login) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/request_code'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'phone': phone, 'login': login}),
          )
          .timeout(const Duration(seconds: 120));

      print('RequestCode response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['detail'] ?? 'Не удалось запросить код');
      }
    } catch (e) {
      print('Error in requestCode: $e');
      rethrow;
    }
  }

  Future<bool> verifyCode(String phone, String code, String? password, String login) async {
    try {
      final token = await _getToken();
      final response = await http
          .post(
            Uri.parse('$baseUrl/verify_code'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': token,
            },
            body: jsonEncode({
              'phone': phone,
              'code': code,
              'password': password,
              'login': login,
            }),
          )
          .timeout(const Duration(seconds: 120));

      print('VerifyCode response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        if (data['username'] != null) {
          await prefs.setString('telegram_username', data['username'] as String);
          await prefs.setString('telegram_phone', phone);
          await prefs.setString('phone', phone);
        }
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['detail'] ?? 'Не удалось подтвердить код');
      }
    } catch (e) {
      print('Error in verifyCode: $e');
      rethrow;
    }
  }

  Future<List<ChannelModel>> getChannels(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final login = prefs.getString('login');
      final accountId = await _getUserId();
      if (login == null || login.isEmpty) {
        throw Exception('Логин не найден. Пожалуйста, войдите снова.');
      }
      if (accountId == null || accountId.isEmpty) {
        throw Exception('Идентификатор аккаунта не найден. Пожалуйста, войдите снова.');
      }
      final token = await _getToken();
      final response = await http
          .post(
            Uri.parse('$baseUrl/channels'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json; charset=UTF-8',
              'Authorization': token,
            },
            body: jsonEncode({
              'phone': phone,
              'login': login,
              'account_id': accountId,
            }),
          )
          .timeout(const Duration(seconds: 1000));

      print('GetChannels response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        return (data['channels'] as List)
            .map((json) => ChannelModel.fromJson(json))
            .toList();
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['detail'] ?? 'Не удалось получить каналы');
      }
    } catch (e) {
      print('Error in getChannels: $e');
      rethrow;
    }
  }

  Future<void> createPost({
    required String phone,
    required List<String> chatUsernames,
    required String title,
    required String description,
    String? scheduleDate,
    List<File>? images,
  }) async {
    try {
      final accountId = await _getUserId();
      if (accountId == null || accountId.isEmpty) {
        throw Exception('Идентификатор аккаунта не найден. Пожалуйста, войдите снова.');
      }

      final token = await _getToken();
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/create_post'));

      request.headers['Authorization'] = token;

      if (images != null && images.isNotEmpty) {
        for (var image in images) {
          final bytes = await image.length();
          if (bytes > 10 * 1024 * 1024) {
            throw Exception('Размер изображения превышает лимит в 10 МБ');
          }
        }
      }

      request.fields['phone'] = phone;
      request.fields['account_id'] = accountId;
      request.fields['chat_usernames'] = jsonEncode(chatUsernames);
      request.fields['title'] = title;
      request.fields['description'] = description;
      if (scheduleDate != null) {
        String normalizedScheduleDate = scheduleDate.replaceAll(RegExp(r'Z+$'), '');
        request.fields['schedule_date'] = normalizedScheduleDate + 'Z';
      }

      if (images != null && images.isNotEmpty) {
        for (var image in images) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'images',
              image.path,
              filename: image.path.split('/').last,
            ),
          );
        }
      }

      final response = await request.send().timeout(const Duration(seconds: 60));
      final responseBody = await response.stream.bytesToString();

      print('CreatePost response: ${response.statusCode} $responseBody'); // Логируем полное тело ответа

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(responseBody);
          // Проверяем статус на русском или английском
          final status = data['status']?.toString().toLowerCase();
          if (status == 'успех' || status == 'success') {
            return; // Успешное выполнение
          } else {
            throw Exception(data['detail'] ?? 'Не удалось создать пост');
          }
        } catch (e) {
          throw Exception('Неверный формат ответа: $responseBody');
        }
      } else {
        try {
          final errorBody = jsonDecode(responseBody);
          final detail = errorBody['detail'] ?? 'Не удалось создать пост';
          if (detail.contains('Failed to send post to the following chats')) {
            throw Exception('$detail. Пожалуйста, проверьте ваши разрешения для указанных каналов.');
          }
          throw Exception(detail);
        } catch (e) {
          throw Exception('Не удалось создать пост: $responseBody');
        }
      }
    } catch (e) {
      print('Error in createPost: $e');
      rethrow;
    }
  }

  Future<List<Map<String, String>>> getTemplates() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$goBaseUrl/api/templates'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 60));

      print('GetTemplates response: Status=${response.statusCode}, Headers=${response.headers}, Body=${response.body}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
        print('Decoded body: $decodedBody');
        final List<dynamic> data = jsonDecode(decodedBody);
        return data.map((template) => {
              'id': template['id'].toString(),
              'name': template['name'].toString(),
              'title': template['title'].toString(),
              'description': template['description'].toString(),
            }).toList();
      } else {
        final decodedErrorBody = utf8.decode(response.bodyBytes, allowMalformed: true);
        print('Error response decoded: $decodedErrorBody');
        final errorBody = jsonDecode(decodedErrorBody);
        throw Exception(errorBody['error'] ?? 'Не удалось получить шаблоны (Статус: ${response.statusCode})');
      }
    } catch (e, stackTrace) {
      print('Error in getTemplates: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> createTemplate({
    required String name,
    required String title,
    required String description,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$goBaseUrl/api/templates'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'name': name,
          'title': title,
          'description': description,
        }),
      ).timeout(const Duration(seconds: 60));

      print('CreateTemplate response: ${response.statusCode} ${response.body}');

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Не удалось создать шаблон');
      }
    } catch (e) {
      print('Error in createTemplate: $e');
      rethrow;
    }
  }

  Future<void> updateTemplate({
    required String templateId,
    required String name,
    required String title,
    required String description,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$goBaseUrl/api/templates/$templateId'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'name': name,
          'title': title,
          'description': description,
        }),
      ).timeout(const Duration(seconds: 60));

      print('UpdateTemplate response: ${response.statusCode} ${response.body}');

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Не удалось обновить шаблон');
      }
    } catch (e) {
      print('Error in updateTemplate: $e');
      rethrow;
    }
  }

  Future<void> deleteTemplate({
    required String templateId,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$goBaseUrl/api/templates/$templateId'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 60));

      print('DeleteTemplate response: ${response.statusCode} ${response.body}');

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Не удалось удалить шаблон');
      }
    } catch (e) {
      print('Error in deleteTemplate: $e');
      rethrow;
    }
  }

  Future<List<PostModel>> getPosts(String userId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$goBaseUrl/api/posts?user_id=$userId'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 60));

      print('GetPosts response: Status=${response.statusCode}, Headers=${response.headers}, Body=${response.body}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
        print('Decoded body: $decodedBody');
        final List<dynamic> data = jsonDecode(decodedBody);
        return data.map((post) => PostModel.fromJson(post)).toList();
      } else {
        final decodedErrorBody = utf8.decode(response.bodyBytes, allowMalformed: true);
        print('Error response decoded: $decodedErrorBody');
        final errorBody = jsonDecode(decodedErrorBody);
        throw Exception(errorBody['error'] ?? 'Не удалось получить посты (Статус: ${response.statusCode})');
      }
    } catch (e, stackTrace) {
      print('Error in getPosts: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$goBaseUrl/api/posts/$postId'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 60));

      print('DeletePost response: ${response.statusCode} ${response.body}');

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Не удалось удалить пост');
      }
    } catch (e) {
      print('Error in deletePost: $e');
      rethrow;
    }
  }

  Future<void> savePostToGoBackend({
    required String userId,
    required String title,
    required String description,
    required List<String> socialIds,
    String? scheduleDate,
    List<File>? images,
  }) async {
    try {
      final token = await _getToken();
      var request = http.MultipartRequest('POST', Uri.parse('$goBaseUrl/api/posts'));

      request.headers['Authorization'] = token;
      request.fields['title'] = title;
      request.fields['description'] = description;
      for (var socialId in socialIds) {
        final formattedSocialId = socialId.startsWith('@') ? socialId : '@$socialId';
        request.fields['social_ids[]'] = formattedSocialId;
        print('Sending social_id: $formattedSocialId');
      }
      if (scheduleDate != null) {
        String normalizedScheduleDate = scheduleDate.replaceAll(RegExp(r'Z+$'), '');
        try {
          final dateTime = DateTime.parse(normalizedScheduleDate).toUtc();
          request.fields['scheduled_at'] = dateTime.toIso8601String().replaceAll(RegExp(r'\.\d+'), '');
          print('Sending scheduled_at: ${request.fields['scheduled_at']}');
        } catch (e) {
          print('Error parsing scheduleDate: $scheduleDate, error: $e');
          throw FormatException('Неверный формат даты: $scheduleDate');
        }
      }

      if (images != null && images.isNotEmpty) {
        for (var image in images) {
          final bytes = await image.length();
          if (bytes > 10 * 1024 * 1024) {
            throw Exception('Размер изображения превышает лимит в 10 МБ');
          }
          request.files.add(
            await http.MultipartFile.fromPath(
              'images',
              image.path,
              filename: image.path.split('/').last,
            ),
          );
        }
      }

      final response = await request.send().timeout(const Duration(seconds: 60));
      final responseBody = await response.stream.bytesToString();

      print('SavePostToGoBackend response: ${response.statusCode} $responseBody');

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(responseBody);
        throw Exception(errorBody['error'] ?? 'Не удалось сохранить пост');
      }
    } catch (e) {
      print('Error in savePostToGoBackend: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUser(String userId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$goBaseUrl/api/user/$userId'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 60));

      print('GetUser response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
        return jsonDecode(decodedBody);
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
        throw Exception(errorBody['error'] ?? 'Не удалось получить данные пользователя');
      }
    } catch (e) {
      print('Error in getUser: $e');
      rethrow;
    }
  }

  Future<List<ChannelModel>> getChannelsByPlatform(String userId, String platform) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$goBaseUrl/api/links?user_id=$userId&platform=$platform'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 60));

      print('GetChannelsByPlatform response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
        final data = jsonDecode(decodedBody);
        return (data['links'] as List)
            .map((json) => ChannelModel.fromJson(json))
            .toList();
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
        throw Exception(errorBody['error'] ?? 'Не удалось получить каналы по платформе');
      }
    } catch (e) {
      print('Error in getChannelsByPlatform: $e');
      rethrow;
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw Exception('Токен не найден. Пожалуйста, войдите в аккаунт.');
    }
    return 'Bearer $token';
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('account_id');
  }
}