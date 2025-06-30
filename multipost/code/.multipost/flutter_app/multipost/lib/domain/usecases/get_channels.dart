import 'package:multipost/data/models/channel_model.dart';
   import 'package:multipost/domain/repositories/auth_repository.dart';

   class GetChannels {
     final AuthRepository repository;

     GetChannels(this.repository);

     Future<List<ChannelModel>> call(String phone) async {
       return await repository.getChannels(phone);
     }

    Future<List<ChannelModel>> byPlatform(String userId, String platform) async {
      return await repository.getChannelsByPlatform(userId, platform);
    }
   }
