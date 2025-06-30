class Channel {
  final String title;
  final String mainUsername;
  final String platform;

  Channel({
    required this.title,
    required this.mainUsername,
    required this.platform,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      title: json['title'],
      mainUsername: json['main_username'],
      platform: json['platform'],
    );
  }
}