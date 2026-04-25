part of 'properties_bloc.dart';

abstract class PropertiesEvent extends Equatable {
  const PropertiesEvent();

  @override
  List<Object?> get props => [];
}

class PropertiesFetchStarted extends PropertiesEvent {}

class PropertiesFilterChanged extends PropertiesEvent {
  final PropertyType? type;
  final double? maxPrice;

  const PropertiesFilterChanged({this.type, this.maxPrice});

  @override
  List<Object?> get props => [type, maxPrice];
}

class PropertiesSearchQueryChanged extends PropertiesEvent {
  final String query;

  const PropertiesSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}
