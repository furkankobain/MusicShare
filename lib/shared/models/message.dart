import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  track,
  album,
  playlist,
  image,
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final MessageType type;
  final String content;
  final Map<String, dynamic>? metadata; // For music shares, image URLs, etc.
  final DateTime timestamp;
  final bool isRead;
  final String? replyTo; // Message ID being replied to

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    required this.content,
    this.metadata,
    required this.timestamp,
    this.isRead = false,
    this.replyTo,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'type': type.name,
      'content': content,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'replyTo': replyTo,
    };
  }

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      senderAvatar: data['senderAvatar'],
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      content: data['content'] ?? '',
      metadata: data['metadata'] as Map<String, dynamic>?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      replyTo: data['replyTo'],
    );
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    MessageType? type,
    String? content,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    bool? isRead,
    String? replyTo,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      replyTo: replyTo ?? this.replyTo,
    );
  }

  // Helper methods for specific message types
  bool get isTrackShare => type == MessageType.track;
  bool get isAlbumShare => type == MessageType.album;
  bool get isPlaylistShare => type == MessageType.playlist;
  bool get isMusicShare => isTrackShare || isAlbumShare || isPlaylistShare;
  bool get isImageShare => type == MessageType.image;
}
