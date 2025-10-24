import 'package:cloud_firestore/cloud_firestore.dart';

class MusicList {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final List<String> trackIds;
  final bool isPublic;
  final List<String> collaborators;
  final int likeCount;
  final int commentCount;
  final String? coverImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;

  MusicList({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.trackIds,
    this.isPublic = true,
    this.collaborators = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.coverImage,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'trackIds': trackIds,
      'isPublic': isPublic,
      'collaborators': collaborators,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'coverImage': coverImage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
    };
  }

  factory MusicList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MusicList(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      trackIds: List<String>.from(data['trackIds'] ?? []),
      isPublic: data['isPublic'] ?? true,
      collaborators: List<String>.from(data['collaborators'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      coverImage: data['coverImage'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  MusicList copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<String>? trackIds,
    bool? isPublic,
    List<String>? collaborators,
    int? likeCount,
    int? commentCount,
    String? coverImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
  }) {
    return MusicList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      trackIds: trackIds ?? this.trackIds,
      isPublic: isPublic ?? this.isPublic,
      collaborators: collaborators ?? this.collaborators,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      coverImage: coverImage ?? this.coverImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }
}
