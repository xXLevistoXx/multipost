import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:multipost/data/models/channel_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class RequestCodeEvent extends AuthEvent {
  final String phone;
  final String login;

  const RequestCodeEvent(this.phone, {required this.login});

  @override
  List<Object?> get props => [phone, login];
}

class VerifyCodeEvent extends AuthEvent {
  final String phone;
  final String code;
  final String? password;
  final String login;

  const VerifyCodeEvent(this.phone, this.code, this.password, {required this.login});

  @override
  List<Object?> get props => [phone, code, password, login];
}

class GetChannelsEvent extends AuthEvent {
  final String phone;

  const GetChannelsEvent(this.phone);

  @override
  List<Object?> get props => [phone];
}

class CreatePostEvent extends AuthEvent {
  final String phone;
  final List<ChannelModel> selectedChannels;
  final String title;
  final String description;
  final List<File>? images;
  final DateTime? scheduleDate;

  const CreatePostEvent({
    required this.phone,
    required this.selectedChannels,
    required this.title,
    required this.description,
    this.images,
    this.scheduleDate,
  });

  @override
  List<Object?> get props => [phone, selectedChannels, title, description, images, scheduleDate];
}

class ResetAuthStateEvent extends AuthEvent {}

class GetChannelsByPlatformEvent extends AuthEvent {
  final String userId;
  final String platform;

  const GetChannelsByPlatformEvent(this.userId, this.platform);

  @override
  List<Object?> get props => [userId, platform];
}