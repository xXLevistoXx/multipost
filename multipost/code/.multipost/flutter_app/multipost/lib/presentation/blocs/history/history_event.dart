import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchPostsEvent extends HistoryEvent {
  final String userId;

  const FetchPostsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class DeletePostEvent extends HistoryEvent {
  final String postId;

  const DeletePostEvent(this.postId);

  @override
  List<Object?> get props => [postId];
}