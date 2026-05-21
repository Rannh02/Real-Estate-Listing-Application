import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/login/presentation/pages/login_page.dart';
import '../../bloc/agent_bloc.dart';
import '../../../properties/presentation/pages/notifications_page.dart';

class AgentProfilePage extends StatelessWidget {
  final String email;
  const AgentProfilePage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF0A1D37);
    const Color gold = Color(0xFFFFD700);
    final initials = email.isNotEmpty ? email[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 60),
                decoration: const BoxDecoration(
                  color: primaryNavy,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: gold,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: Center(
                        child: Text(initials, style: GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.w800, color: primaryNavy)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('EstateX Agent', style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(email, style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: gold.withOpacity(0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.verified, color: gold, size: 14),
                        const SizedBox(width: 6),
                        Text('Verified Seller', style: GoogleFonts.inter(color: gold, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats card
              BlocBuilder<AgentBloc, AgentState>(
                builder: (context, state) {
                  final count = state.listings.length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stat(count.toString(), 'Listings', Icons.home_work_outlined, primaryNavy),
                          Container(width: 1, height: 40, color: Colors.grey.shade200),
                          _stat('4.5', 'Avg. Rating', Icons.star_outline, Colors.amber.shade700),
                          Container(width: 1, height: 40, color: Colors.grey.shade200),
                          _stat('Active', 'Status', Icons.circle, Colors.green.shade600),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Info rows
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    children: [
                      _infoRow(Icons.email_outlined, 'Email', email),
                      Divider(height: 1, color: Colors.grey.shade100),
                      _infoRow(Icons.badge_outlined, 'Role', 'Property Agent / Seller'),
                      Divider(height: 1, color: Colors.grey.shade100),
                      _infoRow(Icons.business_outlined, 'Agency', '8990 EstateX'),
                      Divider(height: 1, color: Colors.grey.shade100),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsPage()),
                          );
                        },
                        child: _infoRow(Icons.notifications_none, 'Notifications', 'View Alerts'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Account Security Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account Security', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: primaryNavy)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => _showChangePasswordDialog(context),
                          icon: const Icon(Icons.lock_outline, size: 20),
                          label: Text('Change Password', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          style: TextButton.styleFrom(
                            foregroundColor: primaryNavy,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            backgroundColor: primaryNavy.withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Logout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text('Log Out', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    const Color primaryNavy = Color(0xFF0A1D37);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change Password', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: primaryNavy)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'New Password',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Confirm New Password',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.isEmpty) return;
              if (passwordController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                return;
              }

              try {
                await FirebaseAuth.instance.currentUser?.updatePassword(passwordController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Update', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0A1D37))),
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
    ]);
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 20, color: const Color(0xFF0A1D37)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0A1D37), fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}
