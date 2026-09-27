class PostModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final String imageUrl;
  final String locationName;
  final double latitude;
  final double longitude;
  final String contactName;
  final String whatsappNumber;
  final String status;
  final String type; // 'found' or 'lost'
  final String valueRange; // e.g., 'Under Rs. 1,000', 'Rs. 10,000 - Rs. 25,000'
  final String? policeStationName;
  final String? policeStationLocation;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.contactName,
    required this.whatsappNumber,
    required this.status,
    required this.type,
    required this.valueRange,
    this.policeStationName,
    this.policeStationLocation,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'Untitled',
      category: (json['category'] as String?) ?? 'Other',
      description: (json['description'] as String?) ?? 'No description provided.',
      imageUrl: (json['image_url'] as String?) ?? 'https://images.unsplash.com/photo-1540553016722-983e48a2cd10?w=800&auto=format&fit=crop&q=60',
      locationName: (json['location_name'] as String?) ?? 'Unknown Location',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      contactName: (json['contact_name'] as String?) ?? 'Unknown Contact',
      whatsappNumber: (json['whatsapp_number'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'active',
      type: (json['type'] as String?) ?? 'found',
      valueRange: (json['value_range'] as String?) ?? 'Under Rs. 1,000',
      policeStationName: json['police_station_name'] as String?,
      policeStationLocation: json['police_station_location'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'contact_name': contactName,
      'whatsapp_number': whatsappNumber,
      'status': status,
      'type': type,
      'value_range': valueRange,
      'police_station_name': policeStationName,
      'police_station_location': policeStationLocation,
    };
  }

  PostModel copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    String? imageUrl,
    String? locationName,
    double? latitude,
    double? longitude,
    String? contactName,
    String? whatsappNumber,
    String? status,
    String? type,
    String? valueRange,
    String? policeStationName,
    String? policeStationLocation,
    DateTime? createdAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      contactName: contactName ?? this.contactName,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      status: status ?? this.status,
      type: type ?? this.type,
      valueRange: valueRange ?? this.valueRange,
      policeStationName: policeStationName ?? this.policeStationName,
      policeStationLocation: policeStationLocation ?? this.policeStationLocation,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
