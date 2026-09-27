import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'appwrite_service.dart';
import '../models/post_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  FirebaseService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  // Firebase is always configured through the google-services configuration files
  bool get isConfigured => true;

  /// Fetch all active posts (status == 'active'), sorted by creation time descending.
  Future<List<PostModel>> getActivePosts() async {
    try {
      final snapshot = await _db
          .collection('posts')
          .where('status', isEqualTo: 'active')
          .get();

      final List<PostModel> posts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        } else if (data['created_at'] is String) {
          // Keep as is
        } else {
          data['created_at'] = DateTime.now().toIso8601String();
        }
        return PostModel.fromJson(data);
      }).toList();

      // Sort client-side to handle missing index gracefully
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    } catch (e) {
      print('Error fetching active posts from Firestore: $e');
      return [];
    }
  }

  /// Upload an image to Appwrite Storage and return the public URL.
  Future<String> uploadImage(File file) async {
    try {
      return await AppwriteService.instance.uploadImage(file);
    } catch (e) {
      print('Error uploading image to Appwrite Storage: $e');
      // Fallback to local path if upload fails
      return file.path;
    }
  }

  /// Create a new post.
  Future<PostModel> createPost({
    required String title,
    required String category,
    required String description,
    required File imageFile,
    required String locationName,
    required double latitude,
    required double longitude,
    required String contactName,
    required String whatsappNumber,
    required String type, // 'found' or 'lost'
    required String valueRange,
    String? policeStationName,
    String? policeStationLocation,
  }) async {
    try {
      // 1. Persist file locally in Application Documents Directory first
      String finalImageUrl = '';
      String localFilename = '';
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final String fileExtension = imageFile.path.split('.').last;
        localFilename = 'post_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
        final localFile = File('${docDir.path}/$localFilename');
        await imageFile.copy(localFile.path);
        print('Saved post image locally: ${localFile.path}');
      } catch (saveErr) {
        print('Error saving image locally: $saveErr');
      }

      // 2. Upload image first
      String imageUrl;
      try {
        imageUrl = await uploadImage(imageFile);
      } catch (e) {
        imageUrl = '';
      }

      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        finalImageUrl = imageUrl;
      } else {
        // Fallback to local persistent identifier
        finalImageUrl = localFilename.isNotEmpty ? 'local_file://$localFilename' : imageFile.path;
      }

      // 3. Insert record into database
      final docRef = await _db.collection('posts').add({
        'title': title,
        'category': category,
        'description': description,
        'image_url': finalImageUrl,
        'location_name': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'contact_name': contactName,
        'whatsapp_number': whatsappNumber,
        'status': 'active',
        'type': type,
        'value_range': valueRange,
        'police_station_name': policeStationName,
        'police_station_location': policeStationLocation,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'created_at': FieldValue.serverTimestamp(),
      });

      final createdDoc = await docRef.get();
      final data = createdDoc.data() ?? {};
      data['id'] = docRef.id;
      
      if (data['created_at'] is Timestamp) {
        data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
      } else {
        data['created_at'] = DateTime.now().toIso8601String();
      }

      // Save created post ID to SharedPreferences list for offline guest tracking
      try {
        final prefs = await SharedPreferences.getInstance();
        final List<String> myPostIds = prefs.getStringList('my_created_posts') ?? [];
        myPostIds.add(docRef.id);
        await prefs.setStringList('my_created_posts', myPostIds);
      } catch (err) {
        print('Error saving post ID to SharedPreferences: $err');
      }

      return PostModel.fromJson(data);
    } catch (e) {
      print('Error creating post in Firestore: $e');
      rethrow;
    }
  }

  /// Mark an item as returned (status = 'returned').
  Future<void> markAsReturned(String id) async {
    try {
      await _db.collection('posts').doc(id).update({'status': 'returned'});
    } catch (e) {
      print('Error updating post status in Firestore: $e');
      rethrow;
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Search posts.
  Future<List<PostModel>> searchPosts({
    String? query,
    String? category,
    String? color,
    String? location,
    String? dateFilter,
    double? latitude,
    double? longitude,
  }) async {
    try {
      var dbQuery = _db.collection('posts').where('status', isEqualTo: 'active');

      if (category != null && category.isNotEmpty && category != 'All') {
        dbQuery = dbQuery.where('category', isEqualTo: category);
      }

      final snapshot = await dbQuery.get();
      var posts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        } else if (data['created_at'] is String) {
          // Keep as is
        } else {
          data['created_at'] = DateTime.now().toIso8601String();
        }
        return PostModel.fromJson(data);
      }).toList();

      // Client-side text filters
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        posts = posts.where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q)).toList();
      }
      if (color != null && color.isNotEmpty) {
        final c = color.toLowerCase();
        posts = posts.where((p) =>
            p.title.toLowerCase().contains(c) ||
            p.description.toLowerCase().contains(c)).toList();
      }
      // Location filter (coordinates proximity or substring fallback)
      if (latitude != null && longitude != null) {
        posts = posts.where((p) => _calculateDistance(p.latitude, p.longitude, latitude, longitude) <= 30.0).toList();
        posts.sort((a, b) {
          final dA = _calculateDistance(a.latitude, a.longitude, latitude, longitude);
          final dB = _calculateDistance(b.latitude, b.longitude, latitude, longitude);
          return dA.compareTo(dB);
        });
      } else if (location != null && location.isNotEmpty) {
        final l = location.toLowerCase();
        posts = posts.where((p) =>
            p.locationName.toLowerCase().contains(l)).toList();
      }
      // Date filter
      if (dateFilter != null && dateFilter.isNotEmpty && dateFilter != 'Anytime') {
        final now = DateTime.now();
        posts = posts.where((p) {
          final diff = now.difference(p.createdAt);
          if (dateFilter == 'Lost today') {
            return diff.inHours < 24;
          } else if (dateFilter == 'Last 3 days') {
            return diff.inDays < 3;
          } else if (dateFilter == 'Last week') {
            return diff.inDays < 7;
          } else if (dateFilter == 'Last month') {
            return diff.inDays < 30;
          }
          return true;
        }).toList();
      }

      // Sort by date descending
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    } catch (e) {
      print('Error searching Firestore posts: $e');
      return [];
    }
  }

  /// Get active posts created by the current user (filtered by UID or fallback contact info)
  Future<List<PostModel>> getMyPosts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final String? uid = user?.uid;
      final String? displayName = user?.displayName;
      final String? phoneNumber = user?.phoneNumber;

      // Fetch local post IDs list from SharedPreferences
      List<String> localPostIds = [];
      try {
        final prefs = await SharedPreferences.getInstance();
        localPostIds = prefs.getStringList('my_created_posts') ?? [];
      } catch (err) {
        print('Error reading post IDs from SharedPreferences: $err');
      }

      final snapshot = await _db.collection('posts').where('status', isEqualTo: 'active').get();
      final List<PostModel> allPosts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        } else if (data['created_at'] is String) {
          // Keep as is
        } else {
          data['created_at'] = DateTime.now().toIso8601String();
        }
        return PostModel.fromJson(data);
      }).toList();

      // Filter to only include posts that match the current user or device
      final List<PostModel> myPosts = allPosts.where((p) {
        // Match 1: Local device preference tracking
        if (localPostIds.contains(p.id)) {
          return true;
        }

        final doc = snapshot.docs.firstWhere((doc) => doc.id == p.id);
        final String? postUserId = doc.data()['userId'] as String?;
        
        // Match 2: Authenticated UID
        if (postUserId != null && uid != null && postUserId == uid) {
          return true;
        }
        
        // Match 3: Contact Name fallback
        if (displayName != null && displayName.isNotEmpty && p.contactName == displayName) {
          return true;
        }
        
        // Match 4: Phone Number fallback
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          final normalizedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
          final normalizedPostPhone = p.whatsappNumber.replaceAll(RegExp(r'\D'), '');
          if (normalizedPhone.isNotEmpty && normalizedPostPhone.contains(normalizedPhone)) {
            return true;
          }
        }
        
        return false;
      }).toList();

      myPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return myPosts;
    } catch (e) {
      print('Error fetching my posts from Firestore: $e');
      return [];
    }
  }

  /// Check if the current user or device is the creator of this post
  Future<bool> isPostOwner(PostModel post) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final String? uid = user?.uid;
      final String? displayName = user?.displayName;
      final String? phoneNumber = user?.phoneNumber;

      // 1. Check local SharedPreferences list
      try {
        final prefs = await SharedPreferences.getInstance();
        final localPostIds = prefs.getStringList('my_created_posts') ?? [];
        if (localPostIds.contains(post.id)) {
          return true;
        }
      } catch (err) {
        print('Error reading post IDs from SharedPreferences: $err');
      }

      // 2. Check if Firestore post has userId matching user's UID
      final doc = await _db.collection('posts').doc(post.id).get();
      if (doc.exists) {
        final String? postUserId = doc.data()?['userId'] as String?;
        if (postUserId != null && uid != null && postUserId == uid) {
          return true;
        }
      }

      // 3. Fallback matching display name/contact name
      if (displayName != null && displayName.isNotEmpty && post.contactName == displayName) {
        return true;
      }

      // 4. Fallback matching phone number
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        final normalizedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
        final normalizedPostPhone = post.whatsappNumber.replaceAll(RegExp(r'\D'), '');
        if (normalizedPhone.isNotEmpty && normalizedPostPhone.contains(normalizedPhone)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking post ownership: $e');
      return false;
    }
  }
}
