import 'dart:io';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/post_model.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  /// Check if the user has updated the configuration with actual keys.
  bool get isConfigured {
    return SupabaseConfig.supabaseUrl != 'YOUR_SUPABASE_URL' &&
        SupabaseConfig.supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
  }

  /// Fetch all active posts (status == 'active'), sorted by creation time descending.
  Future<List<PostModel>> getActivePosts() async {
    if (!isConfigured) {
      return _getMockPosts();
    }

    try {
      final response = await _client
          .from('posts')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching active posts: $e');
      rethrow;
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Search posts by query, category, color keywords, and/or location (coordinates proximity or text).
  Future<List<PostModel>> searchPosts({
    String? query,
    String? category,
    String? color,
    String? location,
    String? dateFilter,
    double? latitude,
    double? longitude,
  }) async {
    if (!isConfigured) {
      var posts = _getMockPosts();

      // Category filter
      if (category != null && category.isNotEmpty && category != 'All') {
        posts = posts.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
      }
      // Name/keyword filter
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        posts = posts.where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q)).toList();
      }
      // Color filter — searches description and title for colour mentions
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
      return posts;
    }

    try {
      var dbQuery = _client.from('posts').select().eq('status', 'active');

      if (category != null && category.isNotEmpty && category != 'All') {
        dbQuery = dbQuery.eq('category', category);
      }

      final response = await dbQuery.order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      var posts = data.map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();

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

      return posts;
    } catch (e) {
      print('Error searching posts: $e');
      rethrow;
    }
  }

  /// Upload an image to Supabase Storage and return the public URL.
  Future<String> uploadImage(File file) async {
    if (!isConfigured) {
      // Return local file path for mock mode so we can display what they upload
      return file.path;
    }

    try {
      final String fileExtension = file.path.split('.').last;
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      
      await _client.storage.from('found_images').upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final String publicUrl = _client.storage.from('found_images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
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
      // 1. Upload image first
      final String imageUrl = await uploadImage(imageFile);

      if (!isConfigured) {
        final mockPost = PostModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          category: category,
          description: description,
          imageUrl: imageUrl,
          locationName: locationName,
          latitude: latitude,
          longitude: longitude,
          contactName: contactName,
          whatsappNumber: whatsappNumber,
          status: 'active',
          type: type,
          valueRange: valueRange,
          policeStationName: policeStationName,
          policeStationLocation: policeStationLocation,
          createdAt: DateTime.now(),
        );
        _mockPosts.insert(0, mockPost);
        return mockPost;
      }

      // 2. Insert record into database
      final response = await _client.from('posts').insert({
        'title': title,
        'category': category,
        'description': description,
        'image_url': imageUrl,
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
      }).select().single();

      return PostModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  /// Mark an item as returned (status = 'returned').
  Future<void> markAsReturned(String id) async {
    if (!isConfigured) {
      final index = _mockPosts.indexWhere((p) => p.id == id);
      if (index != -1) {
        _mockPosts[index] = _mockPosts[index].copyWith(status: 'returned');
      }
      return;
    }

    try {
      await _client
          .from('posts')
          .update({'status': 'returned'})
          .eq('id', id);
    } catch (e) {
      print('Error updating post status: $e');
      rethrow;
    }
  }

  // --- Mock Data for Testing before Supabase configuration is set ---
  final List<PostModel> _mockPosts = [
    PostModel(
      id: 'mock-1',
      title: 'iPhone 15 Pro Max',
      category: 'Phone',
      description: 'Found a black iPhone 15 Pro Max near the central park bench. It has a blue silicon cover and is locked. The screen is slightly scratched but fully functional.',
      imageUrl: 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=800&auto=format&fit=crop&q=60',
      locationName: 'Central Park East Bench, NY',
      latitude: 40.785091,
      longitude: -73.968285,
      contactName: 'Sarah Jenkins',
      whatsappNumber: '15550199',
      status: 'active',
      type: 'found',
      valueRange: 'Above Rs. 25,000',
      policeStationName: 'Central Park Police Substation',
      policeStationLocation: '86th St Transverse, New York, NY 10024',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    PostModel(
      id: 'mock-2',
      title: 'Brown Leather Wallet',
      category: 'Wallet',
      description: 'Found a brown leather wallet containing some cards (no cash) on the floor of Starbucks. Please identify the names on the cards to claim.',
      imageUrl: 'https://images.unsplash.com/photo-1627124765135-56c67c513e3c?w=800&auto=format&fit=crop&q=60',
      locationName: 'Starbucks 5th Avenue, NY',
      latitude: 40.758896,
      longitude: -73.985130,
      contactName: 'David Miller',
      whatsappNumber: '15550143',
      status: 'active',
      type: 'found',
      valueRange: 'Rs. 1,000 - Rs. 5,000',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PostModel(
      id: 'mock-3',
      title: 'Keys with Keychain',
      category: 'Keys',
      description: 'Found a bunch of keys with a metallic astronaut keychain. Found near the parking lot of the mall.',
      imageUrl: 'https://images.unsplash.com/photo-1582139329536-e7284fece509?w=800&auto=format&fit=crop&q=60',
      locationName: 'Queens Mall Parking Lot B',
      latitude: 40.7345,
      longitude: -73.8710,
      contactName: 'Alex Mercer',
      whatsappNumber: '15550187',
      status: 'active',
      type: 'found',
      valueRange: 'Under Rs. 1,000',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    PostModel(
      id: 'mock-4',
      title: 'Lost Golden Retriever',
      category: 'Other',
      description: 'My golden retriever ran away from home last night. He responds to the name Cooper. He is wearing a red collar with a tag. Please contact me if spotted.',
      imageUrl: 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=800&auto=format&fit=crop&q=60',
      locationName: 'Brooklyn Bridge Park, NY',
      latitude: 40.7022,
      longitude: -73.9965,
      contactName: 'Emily Stone',
      whatsappNumber: '15550210',
      status: 'active',
      type: 'lost',
      valueRange: 'Above Rs. 25,000',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    PostModel(
      id: 'mock-5',
      title: 'Lost Bose Headphones',
      category: 'Earbuds',
      description: 'Lost my black Bose QuietComfort headphones on the subway (L train) this morning. They were inside a black zipper case. Any info would be highly appreciated.',
      imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&auto=format&fit=crop&q=60',
      locationName: 'Subway L Train (8th Ave Station)',
      latitude: 40.7397,
      longitude: -74.0025,
      contactName: 'John Doe',
      whatsappNumber: '15550212',
      status: 'active',
      type: 'lost',
      valueRange: 'Rs. 10,000 - Rs. 25,000',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  List<PostModel> _getMockPosts() {
    return [];
  }
}
