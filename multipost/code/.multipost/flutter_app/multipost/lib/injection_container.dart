import 'package:get_it/get_it.dart';
import 'package:multipost/data/datasources/remote_datasource.dart';
import 'package:multipost/data/repositories/auth_repository_impl.dart';
import 'package:multipost/domain/repositories/auth_repository.dart';
import 'package:multipost/domain/usecases/create_post.dart';
import 'package:multipost/domain/usecases/delete_post.dart';
import 'package:multipost/domain/usecases/get_channels.dart';
import 'package:multipost/domain/usecases/get_posts.dart';
import 'package:multipost/domain/usecases/request_code.dart';
import 'package:multipost/domain/usecases/verify_code.dart';
import 'package:multipost/presentation/blocs/auth/auth_bloc.dart';
import 'package:multipost/presentation/blocs/history/history_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Data Sources
  sl.registerLazySingleton<RemoteDataSource>(() => RemoteDataSource());

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // Use Cases
  sl.registerLazySingleton(() => RequestCode(sl()));
  sl.registerLazySingleton(() => VerifyCode(sl()));
  sl.registerLazySingleton(() => GetChannels(sl()));
  sl.registerLazySingleton(() => CreatePost(sl()));
  sl.registerLazySingleton(() => GetPosts(sl()));
  sl.registerLazySingleton(() => DeletePost(sl()));

  // Blocs
  sl.registerFactory(() => AuthBloc(
        requestCode: sl(),
        verifyCode: sl(),
        getChannels: sl(),
        createPost: sl(),
      ));
  sl.registerFactory(() => HistoryBloc(
        getPosts: sl(),
        deletePost: sl(),
      ));
}