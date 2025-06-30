class ChannelModel {
  final String title;
  final String mainUsername;
  final String? platform;

  ChannelModel({
    required this.title,
    required this.mainUsername,
    this.platform,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      title: json['title'] ?? '',
      mainUsername: json['main_username'] ?? '',
      platform: json['platform'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'main_username': mainUsername,
      'platform': platform,
    };
  }

  String getSocialName() {
    if (platform != null) {
      switch (platform!.toLowerCase()) {
        case 'vk':
          return 'ВКонтакте';
        case 'telegram':
          return 'Telegram';
        case 'reddit':
          return 'Reddit';
        default:
          return 'Неизвестно';
      }
    }
    // Резервная логика на основе mainUsername
    if (mainUsername.startsWith('@')) {
      return 'Telegram';
    }
    return 'ВКонтакте';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelModel &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          mainUsername == other.mainUsername &&
          platform == other.platform;

  @override
  int get hashCode => title.hashCode ^ mainUsername.hashCode ^ (platform?.hashCode ?? 0);
}