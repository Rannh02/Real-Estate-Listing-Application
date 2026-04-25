import 'package:equatable/equatable.dart';

enum PropertyType { bungalow, townhouse, apartment, villa, condo }

class Property extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final PropertyType type;
  final String address;
  final String imageUrl;
  final double rating;
  final int bedrooms;
  final num bathrooms;
  final double area;

  const Property({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.type,
    required this.address,
    required this.imageUrl,
    this.rating = 4.5,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        price,
        type,
        address,
        imageUrl,
        rating,
        bedrooms,
        bathrooms,
        area,
      ];
}
