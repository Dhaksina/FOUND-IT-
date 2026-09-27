class AppwriteConfig {
  // Replace with your actual Appwrite Endpoint, Project ID and Storage Bucket ID
  static const String endpoint = 'https://cloud.appwrite.io/v1';
  static const String projectId = '6a4a9a1500399cdb9a8e';
  static const String bucketId = '6a4a9ba00025a11b8c39';

  static bool get isConfigured {
    return projectId.isNotEmpty && 
           projectId != 'YOUR_APPWRITE_PROJECT_ID' &&
           bucketId.isNotEmpty && 
           bucketId != 'YOUR_APPWRITE_BUCKET_ID';
  }
}
