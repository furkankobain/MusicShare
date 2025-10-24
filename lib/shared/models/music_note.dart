import 'package:cloud_firestore/cloud_firestore.dart';

class MusicNote {
  final String id;
  final String userId;
  final String username;
  final String? userAvatar;
  final String trackId;
  final String trackName;
  final String artists;
  final String? albumImage;
  final int? rating; // 1-5 stars, opsiyonel
  final String noteText;
  final bool containsSpoiler;
  final List<String> tags;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  MusicNote({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.trackId,
    required this.trackName,
    required this.artists,
    this.albumImage,
    this.rating,
    required this.noteText,
    this.containsSpoiler = false,
    this.tags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'trackId': trackId,
      'trackName': trackName,
      'artists': artists,
      'albumImage': albumImage,
      'rating': rating,
      'noteText': noteText,
      'containsSpoiler': containsSpoiler,
      'tags': tags,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory MusicNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MusicNote(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userAvatar: data['userAvatar'],
      trackId: data['trackId'] ?? '',
      trackName: data['trackName'] ?? '',
      artists: data['artists'] ?? '',
      albumImage: data['albumImage'],
      rating: data['rating'],
      noteText: data['noteText'] ?? '',
      containsSpoiler: data['containsSpoiler'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  MusicNote copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatar,
    String? trackId,
    String? trackName,
    String? artists,
    String? albumImage,
    int? rating,
    String? noteText,
    bool? containsSpoiler,
    List<String>? tags,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MusicNote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      trackId: trackId ?? this.trackId,
      trackName: trackName ?? this.trackName,
      artists: artists ?? this.artists,
      albumImage: albumImage ?? this.albumImage,
      rating: rating ?? this.rating,
      noteText: noteText ?? this.noteText,
      containsSpoiler: containsSpoiler ?? this.containsSpoiler,
      tags: tags ?? this.tags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
