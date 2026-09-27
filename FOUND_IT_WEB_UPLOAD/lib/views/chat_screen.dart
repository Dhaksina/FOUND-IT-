import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../services/chat_service.dart';
import 'widgets/custom_image.dart';

class SecureChatScreen extends ConsumerStatefulWidget {
  final PostModel post;

  const SecureChatScreen({Key? key, required this.post}) : super(key: key);

  @override
  _SecureChatScreenState createState() => _SecureChatScreenState();
}

class _SecureChatScreenState extends ConsumerState<SecureChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  
  @override
  void initState() {
    super.initState();
    _checkAndSendInitialMessage();
  }

  Future<void> _checkAndSendInitialMessage() async {
    final post = widget.post;
    final isLost = post.type == 'lost';
    
    // Check if the chat document already exists in Firestore
    final doc = await FirebaseFirestore.instance.collection('chats').doc(post.id).get();
    if (!doc.exists) {
      // Send initial introductory message
      await ChatService.instance.sendMessage(
        postId: post.id,
        senderId: 'other',
        text: isLost 
            ? "Hello, thank you for reaching out. I lost my ${post.title} in the ${post.locationName} area. Did you find it?"
            : "Hello, I reported finding a ${post.title} near ${post.locationName}. If this belongs to you, please let me know so we can verify ownership.",
        post: post,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    // Send user message to Firestore
    await ChatService.instance.sendMessage(
      postId: widget.post.id,
      senderId: 'me',
      text: text,
      post: widget.post,
    );

    _scrollToBottom();
    _simulateReply(text);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _simulateReply(String userMessage) {
    setState(() {
      _isTyping = true;
    });
    _scrollToBottom();

    Timer(const Duration(milliseconds: 1800), () async {
      if (!mounted) return;

      String replyText = "";
      final lowercaseMsg = userMessage.toLowerCase();
      
      if (lowercaseMsg.contains('meet') || lowercaseMsg.contains('where') || lowercaseMsg.contains('location')) {
        replyText = "Let's arrange to meet in a public location. For our safety, I suggest the nearest police station: ${widget.post.policeStationName ?? 'the station suggested in post details'}.";
      } else if (lowercaseMsg.contains('verify') || lowercaseMsg.contains('proof') || lowercaseMsg.contains('photo') || lowercaseMsg.contains('image')) {
        replyText = "I can share details to verify ownership. Please make sure your Government ID is verified in Settings so we can exchange pictures securely.";
      } else if (lowercaseMsg.contains('hello') || lowercaseMsg.contains('hi')) {
        replyText = "Hello! Let me know if you have details about the ${widget.post.title}.";
      } else {
        replyText = "Thank you. Let's arrange a safe return. Remember to check location details and coordinate safely in public view.";
      }

      await ChatService.instance.sendMessage(
        postId: widget.post.id,
        senderId: 'other',
        text: replyText,
        post: widget.post,
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final otherName = post.contactName;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Text(
                otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Active Now',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              _showChatSafetyDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Security disclaimer banner
          Container(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🔒 Masked Identity Chat: Your contact details remain private.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chat item preview context
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImage(
                    imageUrl: post.imageUrl,
                    category: post.category,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Category: ${post.category} • ${post.type.toUpperCase()}',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Messages list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: ChatService.instance.streamMessages(post.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = snapshot.data ?? [];
                
                // Trigger auto-scroll on new message layout
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == 'me';
                    final text = message['text'] ?? '';
                    final Timestamp? timeTimestamp = message['time'] as Timestamp?;
                    final time = timeTimestamp != null ? timeTimestamp.toDate() : DateTime.now();
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
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
                              text,
                              style: TextStyle(
                                color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: isMe 
                                      ? theme.colorScheme.onPrimary.withOpacity(0.6) 
                                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      '$otherName is typing',
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(width: 4),
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  ],
                ),
              ),
            ),

          // Text entry field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type a secure message...',
                        hintStyle: TextStyle(color: theme.colorScheme.outline),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatSafetyDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Secure Chat Info'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Masked details: Your true mobile number is hidden. Finders/owners can only contact you inside the platform unless you choose to share details.',
              style: TextStyle(height: 1.4),
            ),
            SizedBox(height: 8),
            Text(
              '• Anti-Fraud warning: Never transfer money or pay delivery charges in advance. Always coordinate handovers at public places, ideally nearest police station.',
              style: TextStyle(height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
