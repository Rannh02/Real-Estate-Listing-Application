import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum PropertyType {
  bungalow,
  townhouse,
  apartment,
  villa,
  condo,
  house;

  static PropertyType fromString(String val) {
    return PropertyType.values.firstWhere(
      (e) => e.name == val.toLowerCase(),
      orElse: () => PropertyType.house,
    );
  }
}

enum PropertyStatus {
  available,
  sold,
  pending,
  forRent;

  static PropertyStatus fromString(String val) {
    return PropertyStatus.values.firstWhere(
      (e) => e.name == val.toLowerCase(),
      orElse: () => PropertyStatus.available,
    );
  }

  String get display {
    switch (this) {
      case PropertyStatus.available: return 'Available';
      case PropertyStatus.sold:      return 'Sold';
      case PropertyStatus.pending:   return 'Pending';
      case PropertyStatus.forRent:   return 'For Rent';
    }
  }
}

class Property extends Equatable {
  // Schema types:
  // propertyID (PK), agentID (FK → Users, idx), propertyType (idx),
  // Status (idx), Price (idx), Bathrooms (idx)

  final String id;           // PK — propertyID
  final String agentID;      // FK → Users (idx)
  final String title;
  final String? caption;
  final String description;
  final double price;        // idx
  final PropertyType type;   // idx — propertyType
  final PropertyStatus status; // idx
  final String location;
  final List<String> imageUrls;
  final int bedrooms;
  final num bathrooms;       // idx
  final double floorArea;
  final int viewCount;
  final bool isSaved;
  final DateTime? datePosted;
  final DateTime? lastUpdated;
  final double? latitude;
  final double? longitude;

  // Kept for backward-compatibility reads
  final String? postedBy;

  const Property({
    required this.id,
    required this.agentID,
    required this.title,
    this.caption,
    required this.description,
    required this.price,
    required this.type,
    required this.status,
    required this.location,
    required this.imageUrls,
    required this.bedrooms,
    required this.bathrooms,
    required this.floorArea,
    this.viewCount = 0,
    this.isSaved = false,
    this.datePosted,
    this.lastUpdated,
    this.postedBy,
    this.latitude,
    this.longitude,
  });

  /// Convenience getter — first image URL or a default
  String get imageUrl =>
      imageUrls.isNotEmpty ? imageUrls.first : 'https://images.unsplash.com/photo-1568605114967-8130f3a36994';

  /// Backward-compat alias
  String get address => location;

  factory Property.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // imageUrls can be a List or a single String (legacy)
    List<String> parseImages(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String && raw.isNotEmpty) return [raw];
      return [];
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    num parseNum(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val;
      if (val is String) return num.tryParse(val) ?? 0;
      return 0;
    }

    return Property(
      id: doc.id,
      agentID: data['agentID'] ?? data['postedBy'] ?? '',                  // FK
      title: data['Title'] ?? data['title'] ?? '',
      caption: data['Caption'] ?? data['caption'],
      description: data['Description'] ?? data['description'] ?? '',
      price: parseDouble(data['Price'] ?? data['price']),                  // idx
      type: PropertyType.fromString(data['propertyType'] ?? data['type'] ?? 'house'), // idx
      status: PropertyStatus.fromString(data['Status'] ?? data['status'] ?? 'available'), // idx
      location: data['Location'] ?? data['address'] ?? '',
      imageUrls: parseImages(data['ImageUrls'] ?? data['imageUrl']),
      bedrooms: parseInt(data['Bedrooms'] ?? data['bedrooms']),
      bathrooms: parseNum(data['Bathrooms'] ?? data['bathrooms']),         // idx
      floorArea: parseDouble(data['floorArea'] ?? data['area']),
      viewCount: parseInt(data['viewCount']),
      isSaved: false,
      datePosted: (data['datePosted'] as Timestamp?)?.toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
      postedBy: data['postedBy'],
      latitude: data['latitude'] != null ? parseDouble(data['latitude']) : null,
      longitude: data['longitude'] != null ? parseDouble(data['longitude']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    // Schema: propertyID(PK), agentID(FK/idx), propertyType(idx),
    //         Status(idx), Price(idx), Bathrooms(idx)
    return {
      'propertyID': id,                    // PK
      'agentID': agentID,                  // FK → Users (idx)
      'propertyType': type.name,           // idx
      'Status': status.display,            // idx
      'Price': price,                      // idx
      'Bathrooms': bathrooms,              // idx
      'Title': title,
      if (caption != null) 'Caption': caption,
      'Description': description,
      'Location': location,
      'ImageUrls': imageUrls,
      'Bedrooms': bedrooms,
      'floorArea': floorArea,
      'viewCount': viewCount,
      'datePosted': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      // Legacy field for backward-compat
      'postedBy': postedBy ?? agentID,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  Property copyWith({
    String? id,
    String? agentID,
    String? title,
    String? caption,
    String? description,
    double? price,
    PropertyType? type,
    PropertyStatus? status,
    String? location,
    List<String>? imageUrls,
    int? bedrooms,
    num? bathrooms,
    double? floorArea,
    int? viewCount,
    bool? isSaved,
    DateTime? datePosted,
    DateTime? lastUpdated,
    String? postedBy,
    double? latitude,
    double? longitude,
  }) {
    return Property(
      id: id ?? this.id,
      agentID: agentID ?? this.agentID,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      description: description ?? this.description,
      price: price ?? this.price,
      type: type ?? this.type,
      status: status ?? this.status,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      floorArea: floorArea ?? this.floorArea,
      viewCount: viewCount ?? this.viewCount,
      isSaved: isSaved ?? this.isSaved,
      datePosted: datePosted ?? this.datePosted,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      postedBy: postedBy ?? this.postedBy,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  List<Object?> get props => [
        id, agentID, title, caption, description, price, type, status,
        location, imageUrls, bedrooms, bathrooms, floorArea,
        viewCount, isSaved, datePosted, lastUpdated, latitude, longitude,
      ];
}
