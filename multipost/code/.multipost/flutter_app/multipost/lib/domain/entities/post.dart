class Post {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final List<String> channels;
  final List<String> platforms;
  final DateTime? scheduledAt;
  final bool published;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.channels,
    required this.platforms,
    this.scheduledAt,
    required this.published,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      images: List<String>.from(json['images'].map((img) => img['data'])),
      channels: List<String>.from(json['channels']),
      platforms: List<String>.from(json['platforms']),
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'])
          : null,
      published: json['published'],
    );
  }
}