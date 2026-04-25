import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/models/property.dart';

part 'properties_event.dart';
part 'properties_state.dart';

class PropertiesBloc extends Bloc<PropertiesEvent, PropertiesState> {
  PropertiesBloc() : super(const PropertiesState()) {
    on<PropertiesFetchStarted>(_onFetchStarted);
    on<PropertiesFilterChanged>(_onFilterChanged);
    on<PropertiesSearchQueryChanged>(_onSearchQueryChanged);
  }

  void _onFetchStarted(PropertiesFetchStarted event, Emitter<PropertiesState> emit) async {
    emit(state.copyWith(status: PropertiesStatus.loading));
    
    // Simulating network delay
    await Future.delayed(const Duration(seconds: 1));

    final mockProperties = [
      const Property(
        id: '1',
        title: 'Modern Villa',
        description: 'A beautiful modern villa with a private pool and ocean view.',
        price: 1250000,
        type: PropertyType.villa,
        address: '123 Ocean Drive, Miami, FL',
        imageUrl: 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=800&q=80',
        bedrooms: 4,
        bathrooms: 3,
        area: 3500,
      ),
      const Property(
        id: '2',
        title: 'Luxury Apartment',
        description: 'High-end apartment in the heart of the city.',
        price: 850000,
        type: PropertyType.apartment,
        address: '456 Skyline Ave, New York, NY',
        imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80',
        bedrooms: 2,
        bathrooms: 2,
        area: 1200,
      ),
      const Property(
        id: '3',
        title: 'Cozy Condo',
        description: 'Perfect for a small family or young professionals.',
        price: 450000,
        type: PropertyType.condo,
        address: '789 Garden St, Austin, TX',
        imageUrl: 'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=800&q=80',
        bedrooms: 2,
        bathrooms: 1,
        area: 950,
      ),
      const Property(
        id: '4',
        title: 'Tropical Bungalow',
        description: 'Spacious bungalow with a large backyard and tropical garden.',
        price: 650000,
        type: PropertyType.bungalow,
        address: '101 Palm Ln, Honolulu, HI',
        imageUrl: 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?auto=format&fit=crop&w=800&q=80',
        bedrooms: 3,
        bathrooms: 2,
        area: 2200,
      ),
      const Property(
        id: '5',
        title: 'Urban Townhouse',
        description: 'Modern townhouse with a rooftop deck and city views.',
        price: 950000,
        type: PropertyType.townhouse,
        address: '202 Metro Blvd, San Francisco, CA',
        imageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
        bedrooms: 3,
        bathrooms: 2.5,
        area: 1800,
      ),
    ];

    emit(state.copyWith(
      status: PropertiesStatus.success,
      properties: mockProperties,
      filteredProperties: mockProperties,
    ));
  }

  void _onFilterChanged(PropertiesFilterChanged event, Emitter<PropertiesState> emit) {
    final type = event.type;
    final maxPrice = event.maxPrice;

    final filtered = state.properties.where((p) {
      final matchesType = type == null || p.type == type;
      final matchesPrice = maxPrice == null || p.price <= maxPrice;
      final matchesSearch = state.searchQuery.isEmpty || 
          p.title.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
          p.address.toLowerCase().contains(state.searchQuery.toLowerCase());
      return matchesType && matchesPrice && matchesSearch;
    }).toList();

    emit(state.copyWith(
      filteredProperties: filtered,
      selectedType: type,
      maxPrice: maxPrice,
    ));
  }

  void _onSearchQueryChanged(PropertiesSearchQueryChanged event, Emitter<PropertiesState> emit) {
    final query = event.query;

    final filtered = state.properties.where((p) {
      final matchesType = state.selectedType == null || p.type == state.selectedType;
      final matchesPrice = state.maxPrice == null || p.price <= state.maxPrice!;
      final matchesSearch = query.isEmpty || 
          p.title.toLowerCase().contains(query.toLowerCase()) ||
          p.address.toLowerCase().contains(query.toLowerCase());
      return matchesType && matchesPrice && matchesSearch;
    }).toList();

    emit(state.copyWith(
      searchQuery: query,
      filteredProperties: filtered,
    ));
  }
}
