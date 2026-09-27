import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class ChatService {
  static final ChatService instance = ChatService._internal();
  ChatService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream messages for a specific post chat thread
  Stream<List<Map<String, dynamic>>> streamMessages(String postId) {
    return _db
        .collection('chats')
        .doc(postId)
        .collection('messages')
        .orderBy('time', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Send a message in a specific post chat thread
  Future<void> sendMessage({
    required String postId,
    required String senderId,
    required String text,
    required PostModel post,
  }) async {
    final time = DateTime.now();
    final messageData = {
      'senderId': senderId,
      'text': text,
      'time': Timestamp.fromDate(time),
    };

    // Add message to subcollection
    await _db
        .collection('chats')
        .doc(postId)
        .collection('messages')
        .add(messageData);

    // Update chat thread summary metadata
    await _db.collection('chats').doc(postId).set({
      'postId': postId,
      'postTitle': post.title,
      'postCategory': post.category,
      'postImageUrl': post.imageUrl,
      'postContactName': post.contactName,
      'postType': post.type,
      'lastMessage': text,
      'lastMessageTime': Timestamp.fromDate(time),
    }, SetOptions(merge: true));
  }

  /// Stream all active chat conversations
  Stream<List<Map<String, dynamic>>> streamChatList() {
    return _db
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Fetch a PostModel by its ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      final doc = await _db.collection('posts').doc(postId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        
        // Convert Timestamp to ISO8601 string for PostModel constructor
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        } else if (data['created_at'] is String) {
          // Keep as is
        } else {
          data['created_at'] = DateTime.now().toIso8601String();
        }

        return PostModel.fromJson(data);
      }
    } catch (e) {
      print('Error fetching post by ID: $e');
    }
    return null;
  }
}
