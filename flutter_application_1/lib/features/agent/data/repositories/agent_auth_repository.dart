import '../models/agent_application.dart';

class AgentAuthRepository {
  static final AgentAuthRepository instance = AgentAuthRepository._internal();
  AgentAuthRepository._internal();

  final List<AgentApplication> _applications = [];
  final List<String> _approvedAgentEmails = ['agent@estatex.com']; // Pre-approved dummy

  List<AgentApplication> getPendingApplications() => 
      _applications.where((a) => a.status == ApplicationStatus.pending).toList();

  void submitApplication(AgentApplication application) {
    _applications.add(application);
  }

  void approveApplication(String id) {
    final index = _applications.indexWhere((a) => a.id == id);
    if (index != -1) {
      _applications[index] = _applications[index].copyWith(status: ApplicationStatus.approved);
      _approvedAgentEmails.add(_applications[index].email);
    }
  }

  bool isAgentApproved(String email) => _approvedAgentEmails.contains(email);
  
  bool isApplicationPending(String email) => 
      _applications.any((a) => a.email == email && a.status == ApplicationStatus.pending);
}
