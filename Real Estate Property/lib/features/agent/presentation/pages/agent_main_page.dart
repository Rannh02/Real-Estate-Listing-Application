import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../bloc/agent_bloc.dart';
import '../../../properties/bloc/properties_bloc.dart';
import '../../../properties/presentation/pages/property_list_page.dart';
import 'agent_listings_page.dart';
import 'agent_dashboard_tab.dart';
import 'add_property_page.dart';
import 'agent_profile_page.dart';
import '../../../../features/chat/presentation/pages/agent_inbox_page.dart';

class AgentMainPage extends StatefulWidget {
  final String email;
  const AgentMainPage({super.key, required this.email});

  @override
  State<AgentMainPage> createState() => _AgentMainPageState();
}

class _AgentMainPageState extends State<AgentMainPage> {
  int _selectedIndex = 0;

  void _switchTab(int index) => setState(() => _selectedIndex = index);

  void _openAddProperty(BuildContext blocContext) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final agentBloc = blocContext.read<AgentBloc>();
        return DraggableScrollableSheet(
          initialChildSize: 0.95,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Close row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New Property Listing',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0A1D37),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 20, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Content
                  Expanded(
                    child: BlocProvider.value(
                      value: agentBloc,
                      child: AddPropertyPage(
                        agentEmail: widget.email,
                        onSuccess: () {
                          Navigator.pop(context);
                          _switchTab(1); // Go to My Listings
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF0A1D37);
    const Color gold = Color(0xFFFFD700);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AgentBloc(agentEmail: widget.email)..add(AgentFetchListings())),
        BlocProvider(create: (_) => PropertiesBloc()..add(PropertiesFetchStarted())),
      ],
      child: Builder(
        builder: (blocContext) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                const AgentDashboardTab(),
                AgentListingsPage(
                  agentEmail: widget.email,
                  onAddTap: () => _openAddProperty(blocContext),
                ),
                AgentInboxPage(agentEmail: widget.email),
                const PropertyListPage(isGuest: false, isAgentMode: true),
                AgentProfilePage(email: widget.email),
              ],
            ),

            // ── FAB for Add Property ─────────────────────────
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton(
                onPressed: () => _openAddProperty(blocContext),
                backgroundColor: primaryNavy,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,

            // ── Bottom Nav ───────────────────────────────────
            bottomNavigationBar: Container(
              height: 85,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _navItem(0, Icons.dashboard, Icons.dashboard_outlined, 'Dashboard')),
                  Expanded(child: _navItem(1, Icons.home_work, Icons.home_work_outlined, 'Listings')),
                  Expanded(child: _navItem(2, Icons.chat_bubble, Icons.chat_bubble_outline, 'Messages')),
                  Expanded(child: _navItem(3, Icons.explore, Icons.explore_outlined, 'Explore')),
                  Expanded(child: _navItem(4, Icons.person, Icons.person_outline, 'Profile')),
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
    
    Widget iconWidget = Icon(sel ? active : inactive, color: sel ? primaryNavy : Colors.grey.shade400, size: 26);
    
    if (index == 2) { // Messages tab
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        iconWidget = StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('messages')
              .where('agentID', isEqualTo: currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasData) {
              // Group by conversationID to find the latest message of each conversation
              final Map<String, Map<String, dynamic>> conversations = {};
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final convId = data['conversationID'] as String?;
                if (convId != null) {
                  final existing = conversations[convId];
                  if (existing == null) {
                    conversations[convId] = data;
                  } else {
                    final existingSendAt = (existing['lastMessageAt'] ?? existing['sendAt']) as Timestamp?;
                    final currentSendAt = (data['lastMessageAt'] ?? data['sendAt']) as Timestamp?;
                    if (existingSendAt == null || (currentSendAt != null && currentSendAt.compareTo(existingSendAt) > 0)) {
                      conversations[convId] = data;
                    }
                  }
                }
              }

              for (var data in conversations.values) {
                final String senderId = data['senderID'] ?? '';
                final bool isUnread = (data['isRead'] == false) && (senderId != currentUser.uid);
                if (isUnread) unreadCount++;
              }
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(sel ? active : inactive, color: sel ? primaryNavy : Colors.grey.shade400, size: 26),
                if (unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      }
    }

    return GestureDetector(
      onTap: () => _switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
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
}
