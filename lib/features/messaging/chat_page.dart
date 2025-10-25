import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../shared/models/conversation.dart';
import '../../shared/models/message.dart';
import '../../shared/services/messaging_service.dart';

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
  final MessagingService _messagingService = MessagingService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  bool _isTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

    await _messagingService.sendMessage(
      conversationId: widget.conversation.id,
      content: content,
      type: MessageType.text,
    );

    _scrollToBottom();
  }

  String _getOtherUserName() {
    final otherUserId = widget.conversation.participants
        .firstWhere((id) => id != _currentUserId);
    return widget.conversation.participantNames?[otherUserId] ?? 'User';
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

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.blue.shade200 : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getOtherUserName()),
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
              stream: _messagingService.getMessages(widget.conversation.id),
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
                  _messagingService.markAsRead(
                    widget.conversation.id,
                    _currentUserId,
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
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    // TODO: Show attachment options
                  },
                ),
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
                      setState(() => _isTyping = value.isNotEmpty);
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
