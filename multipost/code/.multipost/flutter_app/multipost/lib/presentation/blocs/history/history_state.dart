import 'package:equatable/equatable.dart';
import 'package:multipost/data/models/post_model.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<PostModel> posts;

  const HistoryLoaded(this.posts);

  @override
  List<Object?> get props => [posts];
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class PostDeleted extends HistoryState {}