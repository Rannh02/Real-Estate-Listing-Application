part of 'properties_bloc.dart';

enum PropertiesStatus { initial, loading, success, failure }

class PropertiesState extends Equatable {
  final PropertiesStatus status;
  final List<Property> properties;
  final List<Property> filteredProperties;
  final PropertyType? selectedType;
  final double? maxPrice;
  final String searchQuery;
  final String? errorMessage;

  const PropertiesState({
    this.status = PropertiesStatus.initial,
    this.properties = const [],
    this.filteredProperties = const [],
    this.selectedType,
    this.maxPrice,
    this.searchQuery = '',
    this.errorMessage,
  });

  PropertiesState copyWith({
    PropertiesStatus? status,
    List<Property>? properties,
    List<Property>? filteredProperties,
    PropertyType? selectedType,
    double? maxPrice,
    String? searchQuery,
    String? errorMessage,
  }) {
    return PropertiesState(
      status: status ?? this.status,
      properties: properties ?? this.properties,
      filteredProperties: filteredProperties ?? this.filteredProperties,
      selectedType: selectedType ?? this.selectedType,
      maxPrice: maxPrice ?? this.maxPrice,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        properties,
        filteredProperties,
        selectedType,
        maxPrice,
        searchQuery,
        errorMessage,
      ];
}
