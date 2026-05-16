import 'package:equatable/equatable.dart';

enum ApplicationStatus { pending, approved, rejected }

class AgentApplication extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String password;
  final String agencyName;
  final String licenseNumber;
  final ApplicationStatus status;
  final DateTime appliedAt;

  const AgentApplication({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.agencyName,
    required this.licenseNumber,
    this.status = ApplicationStatus.pending,
    required this.appliedAt,
  });

  AgentApplication copyWith({
    ApplicationStatus? status,
  }) {
    return AgentApplication(
      id: id,
      fullName: fullName,
      email: email,
      password: password,
      agencyName: agencyName,
      licenseNumber: licenseNumber,
      status: status ?? this.status,
      appliedAt: appliedAt,
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, agencyName, licenseNumber, status, appliedAt];
}
