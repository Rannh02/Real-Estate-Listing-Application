import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/properties/data/repositories/property_repository.dart';
import 'package:flutter_application_1/features/login/presentation/pages/login_page.dart';
import 'package:flutter_application_1/features/properties/data/models/property.dart';
import 'package:flutter_application_1/features/properties/presentation/pages/property_details_page.dart';
import 'package:flutter_application_1/features/properties/bloc/properties_bloc.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF0A1D37);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _OverviewTab(),
          _ApplicationsTab(onUpdate: () => setState(() {})),
          _PropertiesTab(onUpdate: () => setState(() {})),
          _AdminProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 85,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: primaryNavy,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Pending'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Postings'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF0A1D37);
    const Color gold = Color(0xFFFFD700);

    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Users').where('Role', isEqualTo: 'agent').where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, agentSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Properties').snapshots(),
            builder: (context, propSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Users').where('Role', isEqualTo: 'agent').where('status', isEqualTo: 'active').snapshots(),
                builder: (context, activeAgentSnapshot) {
                  final pendingCount = agentSnapshot.hasData ? agentSnapshot.data!.docs.length : 0;
                  final totalProperties = propSnapshot.hasData ? propSnapshot.data!.docs.length : 0;
                  final activeCount = activeAgentSnapshot.hasData ? activeAgentSnapshot.data!.docs.length : 0;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('System Overview', style: GoogleFonts.inter(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('Admin Dashboard', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w800, color: primaryNavy)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.4,
                          children: [
                            _statCard('Pending Agents', pendingCount.toString(), Icons.pending_actions, gold),
                            _statCard('Total Listings', totalProperties.toString(), Icons.home_work_outlined, Colors.blue),
                            _statCard('Active Agents', activeCount.toString(), Icons.verified_user_outlined, Colors.green),
                            _statCard('System Status', 'Active', Icons.check_circle_outline, Colors.purple),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        Text('Recent Activity', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: primaryNavy)),
                        const SizedBox(height: 16),
                        _activityTile('New agent application received', 'Just now'),
                        _activityTile('Property listing approved', '45 minutes ago'),
                        _activityTile('System backup completed', '3 hours ago'),
                      ],
                    ),
                  );
                }
              );
            }
          );
        }
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0A1D37))),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _activityTile(String title, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Color(0xFFFFD700)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(time, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ApplicationsTab extends StatelessWidget {
  final VoidCallback onUpdate;
  const _ApplicationsTab({required this.onUpdate});

  /// Approve the agent — updates both Users and Agent Credentials
  Future<void> _approveAgent(BuildContext context, String userDocId) async {
    final adminUID = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
    final firestore = FirebaseFirestore.instance;

    // 1. Update Users: status → active
    await firestore.collection('Users').doc(userDocId).update({
      'status': 'active',
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // 2. Find the Agent Credentials doc by AgentID (FK)
    final credQuery = await firestore
        .collection('Agent Credentials')
        .where('AgentID', isEqualTo: userDocId)
        .get();

    for (final credDoc in credQuery.docs) {
      await credDoc.reference.update({
        'verificationStatus': 'approved',        // idx
        'verifiedAt': FieldValue.serverTimestamp(), // filled by admin
        'verifiedBy': adminUID,                  // FK → Users (admin)
      });
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Agent approved successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// Reject the agent — updates both Users and Agent Credentials
  Future<void> _rejectAgent(BuildContext context, String userDocId) async {
    final adminUID = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
    final firestore = FirebaseFirestore.instance;

    // 1. Update Users: status → rejected
    await firestore.collection('Users').doc(userDocId).update({
      'status': 'rejected',
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // 2. Find the Agent Credentials doc by AgentID (FK)
    final credQuery = await firestore
        .collection('Agent Credentials')
        .where('AgentID', isEqualTo: userDocId)
        .get();

    for (final credDoc in credQuery.docs) {
      await credDoc.reference.update({
        'verificationStatus': 'rejected',
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': adminUID,                  // FK → Users (admin)
      });
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Agent application rejected.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF0A1D37);
    const Color gold = Color(0xFFFFD700);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pending Applications',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: primaryNavy)),
                Text('Review and verify agent credentials',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .where('Role', isEqualTo: 'agent')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: primaryNavy));
                }

                final pendingDocs = snapshot.data?.docs ?? [];

                if (pendingDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 64, color: Colors.green.shade300),
                        const SizedBox(height: 16),
                        Text('No pending applications',
                            style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        Text('All agents have been reviewed',
                            style: GoogleFonts.inter(
                                color: Colors.grey.shade400, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: pendingDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        pendingDocs[index].data() as Map<String, dynamic>;
                    final userDocId = pendingDocs[index].id;
                    final firstName = data['firstname'] ?? '';
                    final lastName = data['lastname'] ?? '';
                    final email = data['Email'] ?? '';
                    final agency = data['agencyName'] ?? 'N/A';
                    final license = data['licenseNumber'] ?? 'N/A';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── Header ───────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: gold.withOpacity(0.15),
                                  child: Text(
                                    firstName.isNotEmpty
                                        ? firstName[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        color: primaryNavy),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('$firstName $lastName',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: primaryNavy)),
                                      Text(email,
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: gold.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: gold.withOpacity(0.4)),
                                  ),
                                  child: Text('PENDING',
                                      style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFB8860B))),
                                ),
                              ],
                            ),
                          ),

                          Divider(height: 1, color: Colors.grey.shade100),

                          // ── Basic Credentials ─────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                    child: _credField(
                                        'AGENCY', agency, Icons.business_outlined)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: _credField(
                                        'LICENSE', license, Icons.badge_outlined)),
                              ],
                            ),
                          ),

                          // ── Agent Credentials from Firestore ──────────────
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('Agent Credentials')
                                .where('AgentID', isEqualTo: userDocId)
                                .limit(1)
                                .get(),
                            builder: (context, credSnap) {
                              if (!credSnap.hasData ||
                                  credSnap.data!.docs.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              final cred = credSnap.data!.docs.first.data()
                                  as Map<String, dynamic>;
                              final expiry =
                                  cred['licenseExpiry'] ?? 'N/A';
                              final years =
                                  cred['yearsExperience'] ?? 'N/A';

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: _credField(
                                            'EXPIRY',
                                            expiry,
                                            Icons.calendar_today_outlined)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: _credField(
                                            'EXP. (YRS)',
                                            years,
                                            Icons.work_history_outlined)),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // ── Action Buttons ────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Row(
                              children: [
                                // Reject
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        title: Text('Reject Application?',
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w800)),
                                        content: Text(
                                            'Reject "$firstName $lastName"\'s agent application?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: Text('Cancel',
                                                  style: GoogleFonts.inter(
                                                      color: Colors.grey))),
                                          ElevatedButton(
                                            onPressed: () async {
                                              Navigator.pop(ctx);
                                              await _rejectAgent(
                                                  context, userDocId);
                                            },
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10))),
                                            child: Text('Reject',
                                                style: GoogleFonts.inter(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    icon: const Icon(Icons.close_rounded,
                                        size: 16),
                                    label: Text('Reject',
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: BorderSide(
                                          color: Colors.red.shade300),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Approve
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        title: Text('Approve Agent?',
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w800)),
                                        content: Text(
                                            'Approve "$firstName $lastName" as a verified agent?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: Text('Cancel',
                                                  style: GoogleFonts.inter(
                                                      color: Colors.grey))),
                                          ElevatedButton(
                                            onPressed: () async {
                                              Navigator.pop(ctx);
                                              await _approveAgent(
                                                  context, userDocId);
                                            },
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.green.shade600,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10))),
                                            child: Text('Approve',
                                                style: GoogleFonts.inter(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    icon: const Icon(Icons.verified_rounded,
                                        size: 16),
                                    label: Text('Approve Agent',
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryNavy,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _credField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.8)),
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A1D37)),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertiesTab extends StatelessWidget {
  final VoidCallback onUpdate;
  const _PropertiesTab({required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF0A1D37);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Post Listings', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w800, color: primaryNavy)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Properties').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final propDocs = snapshot.data?.docs ?? [];

                if (propDocs.isEmpty) {
                  return Center(child: Text('No active postings', style: GoogleFonts.inter(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: propDocs.length,
                  itemBuilder: (context, index) {
                    final p = Property.fromFirestore(propDocs[index]);
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (context) => PropertiesBloc()..add(PropertiesFetchStarted()),
                              child: PropertyDetailsPage(property: p),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                              child: Image.network(p.imageUrl, width: 100, height: 100, fit: BoxFit.cover, 
                                errorBuilder: (ctx, err, stack) => Container(width: 100, height: 100, color: Colors.grey.shade200, child: const Icon(Icons.home))),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: primaryNavy), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.person, size: 12, color: Colors.grey.shade400),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(p.postedBy ?? 'System', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500), maxLines: 1)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('₱${p.price.toInt()}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: primaryNavy)),
                                  ],
                                ),
                              ),
                            ),
                            if (p.status == PropertyStatus.pending)
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: Text('Approve Listing?', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                                      content: Text('Approve "${p.title}" to make it Available?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey))),
                                        ElevatedButton(
                                          onPressed: () async {
                                            await FirebaseFirestore.instance.collection('Properties').doc(p.id).update({
                                              'Status': 'Available',
                                              'lastUpdated': FieldValue.serverTimestamp(),
                                            });
                                            if (ctx.mounted) Navigator.pop(ctx);
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                          child: Text('Approve', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                                  child: Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 20),
                                ),
                              ),
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: Text('Terminate Listing?', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                                    content: Text('This will remove "${p.title}" from all users. Proceed?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey))),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await PropertyRepository.instance.delete(p.id);
                                          if (ctx.mounted) Navigator.pop(ctx);
                                          onUpdate();
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                        child: Text('Terminate', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.delete_sweep_outlined, color: Colors.red.shade400, size: 20),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}


class _AdminProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF0A1D37);
    const Color gold = Color(0xFFFFD700);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: gold,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: gold.withOpacity(0.3), blurRadius: 20)],
              ),
              child: const Center(
                child: Icon(Icons.admin_panel_settings, size: 50, color: primaryNavy),
              ),
            ),
            const SizedBox(height: 24),
            Text('System Administrator', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w800, color: primaryNavy)),
            Text('admin@estatex.com', style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 40),
            
            _profileItem(Icons.badge_outlined, 'Role', 'Super Admin'),
            _profileItem(Icons.security_outlined, 'Access Level', 'Full System Control'),
            _profileItem(Icons.history_outlined, 'Last Login', 'Today, 18:45'),
            
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false),
                icon: const Icon(Icons.logout_rounded),
                label: Text('Log Out', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0A1D37), size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
              Text(value, style: GoogleFonts.inter(color: const Color(0xFF0A1D37), fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

