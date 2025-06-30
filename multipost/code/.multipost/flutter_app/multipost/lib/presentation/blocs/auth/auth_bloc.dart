import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multipost/domain/usecases/create_post.dart';
import 'package:multipost/domain/usecases/get_channels.dart';
import 'package:multipost/domain/usecases/request_code.dart';
import 'package:multipost/domain/usecases/verify_code.dart';
import 'package:multipost/data/datasources/remote_datasource.dart';
import 'package:multipost/presentation/blocs/auth/auth_event.dart';
import 'package:multipost/presentation/blocs/auth/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RequestCode requestCode;
  final VerifyCode verifyCode;
  final GetChannels getChannels;
  final CreatePost createPost;
  final RemoteDataSource _remoteDataSource = RemoteDataSource();

  AuthBloc({
    required this.requestCode,
    required this.verifyCode,
    required this.getChannels,
    required this.createPost,
  }) : super(AuthInitial()) {
    on<RequestCodeEvent>(_onRequestCode);
    on<VerifyCodeEvent>(_onVerifyCode);
    on<GetChannelsEvent>(_onGetChannels);
    on<CreatePostEvent>(_onCreatePost);
    on<ResetAuthStateEvent>(_onResetAuthState);
    on<GetChannelsByPlatformEvent>(_onGetChannelsByPlatform);
  }

  Future<void> _onRequestCode(RequestCodeEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final success = await requestCode(event.phone, event.login);
      if (success) {
        emit(AuthCodeSent());
      } else {
        emit(const AuthError('Не удалось отправить код'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onVerifyCode(VerifyCodeEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final success = await verifyCode(event.phone, event.code, event.password, event.login);
      if (success) {
        emit(AuthVerified());
      } else {
        emit(const AuthError('Ошибка авторизации'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onGetChannels(GetChannelsEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final channels = await getChannels(event.phone);
      emit(AuthChannelsLoaded(channels));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCreatePost(CreatePostEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      print("CreatePostEvent received:");
      print("Phone: ${event.phone}");
      print("Selected Channels: ${event.selectedChannels.map((channel) => channel.mainUsername).toList()}");
      print("Title: ${event.title}");
      print("Description: ${event.description}");
      print("Schedule Date: ${event.scheduleDate?.toIso8601String()}");
      print("Images: ${event.images?.map((image) => image.path).toList() ?? 'No images'}");

      await createPost(
        phone: event.phone,
        chatUsernames: event.selectedChannels.map((channel) => channel.mainUsername).toList(),
        title: event.title,
        description: event.description,
        images: event.images,
        scheduleDate: event.scheduleDate != null
            ? event.scheduleDate!.toIso8601String().replaceAll(RegExp(r'\.\d+'), '') + 'Z'
            : null,
      );

      emit(AuthPostCreated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onResetAuthState(ResetAuthStateEvent event, Emitter<AuthState> emit) async {
    emit(AuthInitial());
  }

  Future<void> _onGetChannelsByPlatform(GetChannelsByPlatformEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final channels = await getChannels.byPlatform(event.userId, event.platform);
      emit(AuthChannelsLoaded(channels));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}