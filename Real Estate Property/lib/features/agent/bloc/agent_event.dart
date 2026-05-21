part of 'agent_bloc.dart';

abstract class AgentEvent extends Equatable {
  const AgentEvent();
  @override
  List<Object?> get props => [];
}

class AgentFetchListings extends AgentEvent {}

class AgentAddProperty extends AgentEvent {
  final Property property;
  const AgentAddProperty(this.property);
  @override
  List<Object?> get props => [property];
}

class AgentDeleteProperty extends AgentEvent {
  final String propertyId;
  const AgentDeleteProperty(this.propertyId);
  @override
  List<Object?> get props => [propertyId];
}
