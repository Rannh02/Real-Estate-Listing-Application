import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_application_1/features/properties/data/models/property.dart';
import 'package:flutter_application_1/features/properties/data/repositories/property_repository.dart';

part 'agent_event.dart';
part 'agent_state.dart';

class AgentBloc extends Bloc<AgentEvent, AgentState> {
  final String agentEmail;

  AgentBloc({required this.agentEmail}) : super(const AgentState()) {
    on<AgentFetchListings>(_onFetchListings);
    on<AgentAddProperty>(_onAddProperty);
    on<AgentDeleteProperty>(_onDeleteProperty);
  }

  void _onFetchListings(AgentFetchListings event, Emitter<AgentState> emit) async {
    emit(state.copyWith(status: AgentStatus.loading));
    final listings = await PropertyRepository.instance.getByAgent(agentEmail);
    emit(state.copyWith(status: AgentStatus.success, listings: listings));
  }

  void _onAddProperty(AgentAddProperty event, Emitter<AgentState> emit) async {
    await PropertyRepository.instance.add(event.property);
    final listings = await PropertyRepository.instance.getByAgent(agentEmail);
    emit(state.copyWith(status: AgentStatus.success, listings: listings));
  }

  void _onDeleteProperty(AgentDeleteProperty event, Emitter<AgentState> emit) async {
    await PropertyRepository.instance.delete(event.propertyId);
    final listings = await PropertyRepository.instance.getByAgent(agentEmail);
    emit(state.copyWith(status: AgentStatus.success, listings: listings));
  }
}
