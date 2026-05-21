import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/models/property.dart';
import '../data/repositories/property_repository.dart';

part 'properties_event.dart';
part 'properties_state.dart';

class PropertiesBloc extends Bloc<PropertiesEvent, PropertiesState> {
  PropertiesBloc() : super(const PropertiesState()) {
    on<PropertiesFetchStarted>(_onFetchStarted);
    on<PropertiesFilterChanged>(_onFilterChanged);
    on<PropertiesSearchQueryChanged>(_onSearchQueryChanged);
    on<PropertiesToggleSave>(_onToggleSave);
    on<PropertiesViewed>(_onPropertiesViewed);
  }

  void _onFetchStarted(PropertiesFetchStarted event, Emitter<PropertiesState> emit) async {
    emit(state.copyWith(status: PropertiesStatus.loading));
    try {
      final properties = await PropertyRepository.instance.getAll();
      emit(state.copyWith(
        status: PropertiesStatus.success,
        properties: properties,
        filteredProperties: properties,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PropertiesStatus.failure,
        errorMessage: e.toString(),
      ));
    }
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

  void _onToggleSave(PropertiesToggleSave event, Emitter<PropertiesState> emit) {
    PropertyRepository.instance.toggleSave(event.propertyId);
    final updatedProperties = state.properties.map((p) {
      if (p.id == event.propertyId) {
        return p.copyWith(isSaved: !p.isSaved);
      }
      return p;
    }).toList();

    final updatedFiltered = updatedProperties.where((p) {
      final matchesType = state.selectedType == null || p.type == state.selectedType;
      final matchesPrice = state.maxPrice == null || p.price <= state.maxPrice!;
      final matchesSearch = state.searchQuery.isEmpty ||
          p.title.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
          p.address.toLowerCase().contains(state.searchQuery.toLowerCase());
      return matchesType && matchesPrice && matchesSearch;
    }).toList();

    emit(state.copyWith(
      properties: updatedProperties,
      filteredProperties: updatedFiltered,
    ));
  }

  void _onPropertiesViewed(PropertiesViewed event, Emitter<PropertiesState> emit) {
    PropertyRepository.instance.incrementViewCount(event.propertyId);
    
    final updatedProperties = state.properties.map((p) {
      if (p.id == event.propertyId) {
        return p.copyWith(viewCount: p.viewCount + 1);
      }
      return p;
    }).toList();

    final updatedFiltered = state.filteredProperties.map((p) {
      if (p.id == event.propertyId) {
        return p.copyWith(viewCount: p.viewCount + 1);
      }
      return p;
    }).toList();

    emit(state.copyWith(
      properties: updatedProperties,
      filteredProperties: updatedFiltered,
    ));
  }
}
