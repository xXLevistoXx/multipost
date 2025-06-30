class LinkModel {
  final String id;
  final String socialId;
  final String platform;
  final String title;
  final String mainUsername;

  LinkModel({
    required this.id,
    required this.socialId,
    required this.platform,
    required this.title,
    required this.mainUsername,
  });

  factory LinkModel.fromJson(Map<String, dynamic> json) {
    return LinkModel(
      id: json['id'] ?? '',
      socialId: json['social_id'] ?? '',
      platform: json['platform'] ?? '',
      title: json['title'] ?? '',
      mainUsername: json['main_username'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'social_id': socialId,
      'platform': platform,
      'title': title,
      'main_username': mainUsername,
    };
  }

  String getSocialName() {
    switch (platform.toLowerCase()) {
      case 'telegram':
        return 'Telegram';
      case 'reddit':
        return 'Reddit';
      case 'vk':
        return 'ВКонтакте';
      default:
        return 'Неизвестно';
    }
  }
}