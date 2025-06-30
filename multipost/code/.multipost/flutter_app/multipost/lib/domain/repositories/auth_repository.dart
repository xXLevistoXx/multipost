import 'dart:io';
import 'package:multipost/data/models/channel_model.dart';
import 'package:multipost/data/models/post_model.dart';

abstract class AuthRepository {
  Future<bool> requestCode(String phone, String login);
  Future<bool> verifyCode(String phone, String code, String? password, String login);
  Future<List<ChannelModel>> getChannels(String phone);
  Future<List<ChannelModel>> getChannelsByPlatform(String userId, String platform);
  Future<void> createPost({
    required String phone,
    required List<String> chatUsernames,
    required String title,
    required String description,
    List<File>? images,
    String? scheduleDate,
  });
  Future<List<PostModel>> getPosts(String userId);
  Future<void> deletePost(String postId);
  Future<void> savePostToGoBackend({
    required String userId,
    required String title,
    required String description,
    required List<String> socialIds,
    String? scheduleDate,
    List<File>? images,
  });
}