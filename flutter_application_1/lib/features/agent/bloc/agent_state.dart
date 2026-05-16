part of 'agent_bloc.dart';

enum AgentStatus { initial, loading, success, failure }

class AgentState extends Equatable {
  final AgentStatus status;
  final List<Property> listings;
  final String? errorMessage;

  const AgentState({
    this.status = AgentStatus.initial,
    this.listings = const [],
    this.errorMessage,
  });

  AgentState copyWith({
    AgentStatus? status,
    List<Property>? listings,
    String? errorMessage,
  }) {
    return AgentState(
      status: status ?? this.status,
      listings: listings ?? this.listings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, listings, errorMessage];
}
