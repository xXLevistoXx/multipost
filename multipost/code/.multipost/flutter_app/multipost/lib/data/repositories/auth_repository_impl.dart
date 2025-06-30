import 'dart:io';
import 'package:multipost/data/datasources/remote_datasource.dart';
import 'package:multipost/data/models/channel_model.dart';
import 'package:multipost/data/models/post_model.dart';
import 'package:multipost/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final RemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<bool> requestCode(String phone, String login) async {
    return await remoteDataSource.requestCode(phone, login);
  }

  @override
  Future<bool> verifyCode(String phone, String code, String? password, String login) async {
    return await remoteDataSource.verifyCode(phone, code, password, login);
  }

  @override
  Future<List<ChannelModel>> getChannels(String phone) async {
    return await remoteDataSource.getChannels(phone);
  }

  
  @override
  Future<List<ChannelModel>> getChannelsByPlatform(String userId, String platform) async {
    return await remoteDataSource.getChannelsByPlatform(userId, platform);
  }
  

  @override
  Future<void> createPost({
    required String phone,
    required List<String> chatUsernames,
    required String title,
    required String description,
    List<File>? images,
    String? scheduleDate,
  }) async {
    await remoteDataSource.createPost(
      phone: phone,
      chatUsernames: chatUsernames,
      title: title,
      description: description,
      images: images,
      scheduleDate: scheduleDate,
    );
  }

  @override
  Future<List<PostModel>> getPosts(String userId) async {
    return await remoteDataSource.getPosts(userId);
  }

  @override
  Future<void> deletePost(String postId) async {
    await remoteDataSource.deletePost(postId);
  }

  @override
  Future<void> savePostToGoBackend({
    required String userId,
    required String title,
    required String description,
    required List<String> socialIds,
    String? scheduleDate,
    List<File>? images,
  }) async {
    await remoteDataSource.savePostToGoBackend(
      userId: userId,
      title: title,
      description: description,
      socialIds: socialIds,
      scheduleDate: scheduleDate,
      images: images,
    );
  }
}