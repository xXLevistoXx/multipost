import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multipost/domain/usecases/delete_post.dart';
import 'package:multipost/domain/usecases/get_posts.dart';
import 'package:multipost/presentation/blocs/history/history_event.dart';
import 'package:multipost/presentation/blocs/history/history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetPosts getPosts;
  final DeletePost deletePost;

  HistoryBloc({
    required this.getPosts,
    required this.deletePost,
  }) : super(HistoryInitial()) {
    on<FetchPostsEvent>(_onFetchPosts);
    on<DeletePostEvent>(_onDeletePost);
  }

  Future<void> _onFetchPosts(FetchPostsEvent event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      final posts = await getPosts(event.userId);
      emit(HistoryLoaded(posts));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  Future<void> _onDeletePost(DeletePostEvent event, Emitter<HistoryState> emit) async {
    try {
      await deletePost(event.postId);
      emit(PostDeleted());
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }
}