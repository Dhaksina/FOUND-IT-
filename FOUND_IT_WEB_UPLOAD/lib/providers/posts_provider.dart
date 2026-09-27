import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/post_model.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as fbs;

/// Notifier for the list of active posts using AsyncNotifier
class PostsNotifier extends AsyncNotifier<List<PostModel>> {
  @override
  Future<List<PostModel>> build() async {
    return ref.read(firebaseServiceProvider).getActivePosts();
  }

  /// Fetch active posts and update state manually
  Future<void> fetchPosts() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(firebaseServiceProvider).getActivePosts());
  }

  /// Create a new post, upload its image, and prepend it to the current list
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
    required String type,
    required String valueRange,
    String? policeStationName,
    String? policeStationLocation,
  }) async {
    try {
      final newPost = await ref.read(firebaseServiceProvider).createPost(
        title: title,
        category: category,
        description: description,
        imageFile: imageFile,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        contactName: contactName,
        whatsappNumber: whatsappNumber,
        type: type,
        valueRange: valueRange,
        policeStationName: policeStationName,
        policeStationLocation: policeStationLocation,
      );
      
      // Update local state if we already have data
      final currentPosts = state.value ?? [];
      state = AsyncValue.data([newPost, ...currentPosts]);
      
      return newPost;
    } catch (e) {
      print('Error in provider createPost: $e');
      rethrow;
    }
  }

  /// Mark a post as returned and remove it from the active listing
  Future<void> markAsReturned(String id) async {
    try {
      await ref.read(firebaseServiceProvider).markAsReturned(id);
      final currentPosts = state.value ?? [];
      state = AsyncValue.data(currentPosts.where((p) => p.id != id).toList());
    } catch (e) {
      print('Error in provider markAsReturned: $e');
      rethrow;
    }
  }
}

// Provider for the Firebase Service
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService.instance;
});

// Provider for the active posts list state
final postsNotifierProvider = AsyncNotifierProvider<PostsNotifier, List<PostModel>>(() {
  return PostsNotifier();
});

// State notifier for search queries
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  
  void updateQuery(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

// State notifier for search category filter
class SearchCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void updateCategory(String value) => state = value;
}

final searchCategoryProvider = NotifierProvider<SearchCategoryNotifier, String>(() {
  return SearchCategoryNotifier();
});

// State notifier for color filter
class SearchColorNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateColor(String value) => state = value;
}

final searchColorProvider = NotifierProvider<SearchColorNotifier, String>(() {
  return SearchColorNotifier();
});

class SearchLocationState {
  final String name;
  final double? latitude;
  final double? longitude;

  SearchLocationState({required this.name, this.latitude, this.longitude});
}

// State notifier for location filter
class SearchLocationNotifier extends Notifier<SearchLocationState> {
  @override
  SearchLocationState build() => SearchLocationState(name: '');

  void updateLocation(String name, {double? latitude, double? longitude}) {
    state = SearchLocationState(name: name, latitude: latitude, longitude: longitude);
  }
}

final searchLocationProvider = NotifierProvider<SearchLocationNotifier, SearchLocationState>(() {
  return SearchLocationNotifier();
});

// State notifier for date filter
class SearchDateNotifier extends Notifier<String> {
  @override
  String build() => 'Anytime';

  void updateDate(String value) => state = value;
}

final searchDateProvider = NotifierProvider<SearchDateNotifier, String>(() {
  return SearchDateNotifier();
});

// FutureProvider for executing search queries (all 5 dimensions)
final searchedPostsProvider = FutureProvider.autoDispose<List<PostModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(searchCategoryProvider);
  final color = ref.watch(searchColorProvider);
  final location = ref.watch(searchLocationProvider);
  final dateFilter = ref.watch(searchDateProvider);
  final service = ref.read(firebaseServiceProvider);
  return await service.searchPosts(
    query: query,
    category: category,
    color: color,
    location: location.name,
    latitude: location.latitude,
    longitude: location.longitude,
    dateFilter: dateFilter,
  );
});

// Provider to fetch user's GPS location with permission handling
final userLocationProvider = FutureProvider<Position?>((ref) async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    return Future.error('Location permissions are permanently denied, we cannot request permissions.');
  } 

  return await Geolocator.getCurrentPosition();
});

class IdVerificationState {
  final bool isVerified;
  final String? idType;
  final String? idImagePath;

  IdVerificationState({
    required this.isVerified,
    this.idType,
    this.idImagePath,
  });
}

class IdVerificationNotifier extends Notifier<IdVerificationState> {
  @override
  IdVerificationState build() {
    return IdVerificationState(isVerified: false);
  }

  Future<void> verifyId(String idType, String imagePath) async {
    String? storageUrl;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final auth = fb.FirebaseAuth.instance;
        final user = auth.currentUser;
        final uid = user?.uid ?? 'anonymous';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${idType.replaceAll(' ', '_')}.jpg';
        
        final storageRef = fbs.FirebaseStorage.instance
            .ref()
            .child('government_ids')
            .child(uid)
            .child(fileName);
            
        final uploadTask = await storageRef.putFile(file);
        storageUrl = await uploadTask.ref.getDownloadURL();
        print('Government ID uploaded successfully to Firebase Storage: $storageUrl');
      }
    } catch (e) {
      print('Error uploading Government ID to Firebase Storage: $e');
      // Fallback to local path if upload fails
    }

    state = IdVerificationState(
      isVerified: true,
      idType: idType,
      idImagePath: storageUrl ?? imagePath,
    );
  }

  void clearVerification() {
    state = IdVerificationState(isVerified: false);
  }
}

final idVerificationProvider = NotifierProvider<IdVerificationNotifier, IdVerificationState>(() {
  return IdVerificationNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ProfilePreferences {
  final String defaultName;
  final String defaultPhone;

  ProfilePreferences({required this.defaultName, required this.defaultPhone});
}

class ProfilePreferencesNotifier extends Notifier<ProfilePreferences> {
  @override
  ProfilePreferences build() {
    return ProfilePreferences(defaultName: '', defaultPhone: '');
  }

  void savePreferences(String name, String phone) {
    state = ProfilePreferences(defaultName: name, defaultPhone: phone);
  }
}

final profilePreferencesProvider = NotifierProvider<ProfilePreferencesNotifier, ProfilePreferences>(() {
  return ProfilePreferencesNotifier();
});

class AuthState {
  final bool isLoggedIn;
  final String? email;
  final String? phoneNumber;
  final String? displayName;

  AuthState({
    required this.isLoggedIn,
    this.email,
    this.phoneNumber,
    this.displayName,
  });
}

class AuthNotifier extends Notifier<AuthState> {
  fb.FirebaseAuth? get _firebaseAuth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return fb.FirebaseAuth.instance;
      }
    } catch (_) {}
    return null;
  }

  @override
  AuthState build() {
    final auth = _firebaseAuth;
    if (auth != null) {
      try {
        final user = auth.currentUser;
        if (user != null) {
          return AuthState(
            isLoggedIn: true,
            email: user.email,
            displayName: user.displayName ?? user.email?.split('@')[0] ?? 'User',
          );
        }
      } catch (e) {
        print('Firebase Auth initialization check error: $e');
      }
    }
    return AuthState(isLoggedIn: false);
  }

  Future<void> loginWithEmail(String email, String password) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      state = AuthState(
        isLoggedIn: true,
        email: email,
        displayName: email.split('@')[0],
      );
      return;
    }

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      state = AuthState(
        isLoggedIn: true,
        email: user?.email,
        displayName: user?.displayName ?? user?.email?.split('@')[0] ?? 'User',
      );
    } catch (e) {
      print('Firebase Sign In error: $e');
      rethrow;
    }
  }

  Future<void> registerWithEmail(String email, String password, String name) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      state = AuthState(
        isLoggedIn: true,
        email: email,
        displayName: name,
      );
      return;
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload();
      }
      final updatedUser = auth.currentUser;
      state = AuthState(
        isLoggedIn: true,
        email: updatedUser?.email,
        displayName: updatedUser?.displayName ?? name,
      );
    } catch (e) {
      print('Firebase Sign Up error: $e');
      rethrow;
    }
  }

  fb.FirebaseAuth? get firebaseAuthInstance => _firebaseAuth;

  Future<void> signInWithPhoneCredential(fb.AuthCredential credential, String name) async {
    final auth = _firebaseAuth;
    if (auth != null) {
      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null && user.displayName == null) {
        await user.updateDisplayName(name);
        await user.reload();
      }
      final updatedUser = auth.currentUser;
      state = AuthState(
        isLoggedIn: true,
        phoneNumber: updatedUser?.phoneNumber,
        displayName: updatedUser?.displayName ?? name,
      );
    }
  }

  Future<void> loginWithPhone(String phone, String name) async {
    state = AuthState(
      isLoggedIn: true,
      phoneNumber: phone,
      displayName: name,
    );
  }

  Future<void> logout() async {
    final auth = _firebaseAuth;
    if (auth != null) {
      try {
        await auth.signOut();
      } catch (e) {
        print('Firebase Sign Out error: $e');
      }
    }
    state = AuthState(isLoggedIn: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
