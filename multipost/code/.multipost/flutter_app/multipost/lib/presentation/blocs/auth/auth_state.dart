import 'package:equatable/equatable.dart';
import 'package:multipost/data/models/channel_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthCodeSent extends AuthState {}

class AuthVerified extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthChannelsLoaded extends AuthState {
  final List<ChannelModel> channels;

  const AuthChannelsLoaded(this.channels);

  @override
  List<Object?> get props => [channels];
}

class AuthPostCreated extends AuthState {}