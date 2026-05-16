import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/agent_bloc.dart';
import 'agent_listings_page.dart';
import 'add_property_page.dart';
import 'agent_profile_page.dart';

class AgentMainPage extends StatefulWidget {
  final String email;
  const AgentMainPage({super.key, required this.email});

  @override
  State<AgentMainPage> createState() => _AgentMainPageState();
}

class _AgentMainPageState extends State<AgentMainPage> {
  int _selectedIndex = 0;

  void _switchTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF0A1D37);

    return BlocProvider(
      create: (_) => AgentBloc(agentEmail: widget.email)..add(AgentFetchListings()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                AgentListingsPage(
                  agentEmail: widget.email,
                  onAddTap: () => _switchTab(1),
                ),
                AddPropertyPage(
                  agentEmail: widget.email,
                  onSuccess: () => _switchTab(0),
                ),
                AgentProfilePage(email: widget.email),
              ],
            ),
            bottomNavigationBar: Container(
              height: 85,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(0, Icons.home_work, Icons.home_work_outlined, 'Listings'),
                  _postButton(context),
                  _navItem(2, Icons.person, Icons.person_outline, 'Profile'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _navItem(int index, IconData active, IconData inactive, String label) {
    final bool sel = _selectedIndex == index;
    const Color primaryNavy = Color(0xFF0A1D37);
    return GestureDetector(
      onTap: () => _switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(sel ? active : inactive, color: sel ? primaryNavy : Colors.grey.shade400, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? primaryNavy : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postButton(BuildContext context) {
    final bool sel = _selectedIndex == 1;
    return GestureDetector(
      onTap: () => _switchTab(1),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFD700) : const Color(0xFF0A1D37),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1D37).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(Icons.add, color: sel ? const Color(0xFF0A1D37) : Colors.white, size: 30),
      ),
    );
  }
}
