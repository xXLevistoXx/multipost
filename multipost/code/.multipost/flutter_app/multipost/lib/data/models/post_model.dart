import 'package:multipost/data/models/link_model.dart';

class PostModel {
  final String id;
  final String title;
  final String description;
  final List<LinkModel> socials;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final bool published;

  PostModel({
    required this.id,
    required this.title,
    required this.description,
    required this.socials,
    required this.createdAt,
    this.scheduledAt,
    required this.published,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      socials: (json['socials'] as List<dynamic>?)
              ?.map((social) => LinkModel.fromJson(social))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at']) : null,
      published: json['published'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'socials': socials.map((social) => social.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'scheduled_at': scheduledAt?.toIso8601String(),
      'published': published,
    };
  }

  String getSocialName() {
    if (socials.isEmpty) return 'Неизвестно';
    return socials.map((social) => social.getSocialName()).toSet().join(', ');
  }
}