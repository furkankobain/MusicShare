import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../shared/models/conversation.dart';
import '../../shared/models/message.dart';
import '../../shared/services/messaging_service.dart';
import '../../shared/services/presence_service.dart';
import '../../shared/services/firebase_storage_service.dart';
import '../../shared/services/firebase_bypass_auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/music_share_card.dart';
import 'widgets/image_message_widget.dart';
import 'widgets/instagram_message_bubble.dart';
import 'widgets/emoji_reaction_picker.dart';

class ChatPage extends StatefulWidget {
  final Conversation conversation;

  const ChatPage({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final String _currentUserId;

  bool _isTyping = false;
  bool _isOtherUserTyping = false;
  bool _isOtherUserOnline = false;
  
  // Debounce timer for typing indicator
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseBypassAuthService.currentUserId ?? '';
    _listenToTypingStatus();
    _listenToOnlineStatus();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _updateTypingStatus(false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _listenToTypingStatus() {
    FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversation.id)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      final data = snapshot.data();
      if (data == null) return;
      
      final typingStatus = data['typingStatus'] as Map<String, dynamic>?;
      if (typingStatus == null) return;
      
      // Get other user's typing status
      final otherUserId = widget.conversation.participantIds
          .firstWhere((id) => id != _currentUserId);
      
      setState(() {
        _isOtherUserTyping = typingStatus[otherUserId] == true;
      });
    });
  }

  void _listenToOnlineStatus() {
    final otherUserId = widget.conversation.participantIds
        .firstWhere((id) => id != _currentUserId);
    
    PresenceService.getUserOnlineStatus(otherUserId).listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOtherUserOnline = isOnline;
        });
      }
    });
  }

  void _updateTypingStatus(bool isTyping) {
    MessagingService.updateTypingStatus(
      conversationId: widget.conversation.id,
      isTyping: isTyping,
    );
  }

  void _onTypingChanged(String text) {
    final isCurrentlyTyping = text.isNotEmpty;
    
    if (isCurrentlyTyping != _isTyping) {
      setState(() => _isTyping = isCurrentlyTyping);
      _updateTypingStatus(isCurrentlyTyping);
    }
    
    // Reset timer
    _typingTimer?.cancel();
    
    if (isCurrentlyTyping) {
      // After 2 seconds of inactivity, mark as not typing
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isTyping = false);
          _updateTypingStatus(false);
        }
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();
    setState(() => _isTyping = false);

    await MessagingService.sendMessage(
      conversationId: widget.conversation.id,
      content: content,
    );

    _scrollToBottom();
  }

  String _getOtherUserName() {
    final otherUserId = widget.conversation.participantIds
        .firstWhere((id) => id != _currentUserId);
    return widget.conversation.participantNames[otherUserId] ?? 'User';
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Dün ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE HH:mm', 'tr').format(timestamp);
    } else {
      return DateFormat('dd.MM.yyyy HH:mm').format(timestamp);
    }
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    String dateText;
    if (difference.inDays == 0) {
      dateText = 'Bugün';
    } else if (difference.inDays == 1) {
      dateText = 'Dün';
    } else if (difference.inDays < 7) {
      dateText = DateFormat('EEEE', 'tr').format(date);
    } else {
      dateText = DateFormat('dd MMMM yyyy', 'tr').format(date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          dateText,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showMessageActions(Message message, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Emoji reactions (Instagram style)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['❤️', '👍', '😂', '😮', '😢', '🔥'].map((emoji) {
                      return GestureDetector(
                        onTap: () {
                          MessagingService.toggleReaction(
                            messageId: message.id,
                            emoji: emoji,
                          );
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const Divider(height: 1),
                
                ListTile(
                  leading: const Icon(Icons.add_reaction_outlined),
                  title: const Text('Daha Fazla Tepki'),
                  onTap: () {
                    Navigator.pop(context);
                    showEmojiReactionPicker(context, message.id);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.reply),
                  title: const Text('Yanıtla'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Yanıtlama özelliği yakında...')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Kopyala'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.content));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mesaj kopyalandı')),
                    );
                  },
                ),
                if (isMe)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Sil', style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Mesajı Sil'),
                          content: const Text('Bu mesajı silmek istediğinize emin misiniz?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('İptal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sil', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final success = await MessagingService.deleteMessage(message.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Mesaj silindi' : 'Mesaj silinemedi'),
                            ),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndSendImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resim gönderiliyor...')),
        );
      }

      // Upload image
      final imageUrl = await FirebaseStorageService.uploadMessageImage(
        imagePath: image.path,
        conversationId: widget.conversation.id,
      );

      if (imageUrl != null) {
        // Send message with image
        await MessagingService.sendMusicShare(
          conversationId: widget.conversation.id,
          type: MessageType.image,
          content: '', // Caption can be empty
          metadata: {'imageUrl': imageUrl},
        );

        _scrollToBottom();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resim gönderildi')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resim yüklenemedi')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    // If image message
    if (message.isImageShare) {
      return GestureDetector(
        onLongPress: () => _showMessageActions(message, isMe),
        child: ImageMessageWidget(
          message: message,
          isMe: isMe,
        ),
      );
    }

    // If music share, use special card
    if (message.isMusicShare) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: GestureDetector(
            onLongPress: () => _showMessageActions(message, isMe),
            child: MusicShareCard(
              message: message,
              isMe: isMe,
            ),
          ),
        ),
      );
    }

    // Regular text message - Instagram style
    return GestureDetector(
      onLongPress: () => _showMessageActions(message, isMe),
      child: InstagramMessageBubble(
        message: message,
        isMe: isMe,
        currentUserId: _currentUserId,
        onReply: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yanıtlama özelliği yakında...')),
          );
        },
        onDelete: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Mesajı Sil'),
              content: const Text('Bu mesajı silmek istediğinize emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sil', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            final success = await MessagingService.deleteMessage(message.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Mesaj silindi' : 'Mesaj silinemedi'),
                ),
              );
            }
          }
        },
        onDoubleTap: () {
          // Quick reaction with heart emoji on double tap (Instagram style)
          MessagingService.toggleReaction(
            messageId: message.id,
            emoji: '❤️',
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (!_isOtherUserTyping) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            '${_getOtherUserName()} yazıyor',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            height: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      width: 4,
                      height: 4 + (value * 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade500,
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                  onEnd: () {
                    if (mounted) setState(() {});
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getOtherUserName()),
            if (_isOtherUserTyping)
              Text(
                'yazıyor...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (_isOtherUserOnline)
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'çevrimiçi',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ],
              )
            else
              Text(
                'çevrimdışı',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show chat options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: MessagingService.getMessages(widget.conversation.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz mesaj yok',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İlk mesajı gönder!',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Mark messages as read
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  MessagingService.markMessagesAsRead(
                    conversationId: widget.conversation.id,
                  );
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    
                    // Show date separator if needed
                    bool showDateSeparator = false;
                    if (index == messages.length - 1) {
                      showDateSeparator = true;
                    } else {
                      final nextMessage = messages[index + 1];
                      final currentDate = DateTime(
                        message.timestamp.year,
                        message.timestamp.month,
                        message.timestamp.day,
                      );
                      final nextDate = DateTime(
                        nextMessage.timestamp.year,
                        nextMessage.timestamp.month,
                        nextMessage.timestamp.day,
                      );
                      showDateSeparator = !currentDate.isAtSameMomentAs(nextDate);
                    }

                    return Column(
                      children: [
                        _buildMessageBubble(message, isMe),
                        if (showDateSeparator)
                          _buildDateSeparator(message.timestamp),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Typing Indicator
          _buildTypingIndicator(),

          // Message Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Image sharing disabled (requires Blaze Plan)
                // IconButton(
                //   icon: const Icon(Icons.image),
                //   onPressed: _pickAndSendImage,
                // ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Mesaj yaz...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) {
                      _onTypingChanged(value);
                    },
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isTyping ? Colors.blue : Colors.grey.shade300,
                  child: IconButton(
                    icon: Icon(
                      _isTyping ? Icons.send : Icons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _isTyping ? _sendMessage : () {
                      // TODO: Voice message
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
