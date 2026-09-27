import 'dart:io';
import 'package:appwrite/appwrite.dart';
import '../config/appwrite_config.dart';

class AppwriteService {
  static final AppwriteService instance = AppwriteService._internal();
  AppwriteService._internal();

  Client? _client;
  Storage? _storage;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    
    if (AppwriteConfig.isConfigured) {
      try {
        _client = Client()
            .setEndpoint(AppwriteConfig.endpoint)
            .setProject(AppwriteConfig.projectId)
            .setSelfSigned(status: true); // Allow self-signed certs for local Appwrite instances
        _storage = Storage(_client!);
        _initialized = true;
        print('Appwrite Service initialized successfully.');
      } catch (e) {
        print('Appwrite Service initialization failed: $e');
      }
    } else {
      print('Appwrite config not configured. Running in fallback local mode.');
    }
  }

  bool get isConfigured => AppwriteConfig.isConfigured;

  Future<String> uploadImage(File file) async {
    if (!isConfigured) {
      print('Appwrite not configured, returning local file path.');
      return file.path;
    }

    try {
      initialize();
      if (_storage == null) {
        throw Exception('Appwrite Storage is not initialized.');
      }

      final String fileExtension = file.path.split('.').last;
      final String fileName = 'post_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      final result = await _storage!.createFile(
        bucketId: AppwriteConfig.bucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: file.path, filename: fileName),
      );

      final String viewUrl = _storage!.getFileView(
        bucketId: AppwriteConfig.bucketId,
        fileId: result.$id,
      ).toString();

      print('Uploaded image to Appwrite: $viewUrl');
      return viewUrl;
    } catch (e) {
      print('Error uploading image to Appwrite: $e');
      rethrow;
    }
  }
}
