import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../properties/presentation/pages/notifications_page.dart';

class AgentDashboardTab extends StatelessWidget {
  const AgentDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF0A1D37);
    const Color gold = Color(0xFFFFD700);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('agentId', isEqualTo: currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            double totalEarnings = 0;
            int totalBookings = 0;
            int paidBookings = 0;
            int pendingBookings = 0;
            double pendingAmount = 0;

            List<Map<String, dynamic>> recentBookings = [];

            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                final status = data['status'] ?? '';

                totalBookings++;

                if (status == 'paid') {
                  paidBookings++;
                  totalEarnings += amount * 0.03; // 3% commission
                } else if (status == 'pending') {
                  pendingBookings++;
                  pendingAmount += amount * 0.03;
                }

                recentBookings.add({
                  ...data,
                  'docId': doc.id,
                });
              }

              // Sort by createdAt descending
              recentBookings.sort((a, b) {
                final aTime = a['createdAt'] as Timestamp?;
                final bTime = b['createdAt'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              // Take only the latest 5
              if (recentBookings.length > 5) {
                recentBookings = recentBookings.sublist(0, 5);
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Agent Dashboard',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Revenue & Performance',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Notifications')
                            .where('recipientID', isEqualTo: currentUser?.uid)
                            .where('isRead', isEqualTo: false)
                            .snapshots(),
                        builder: (context, notifSnapshot) {
                          final unreadCount = notifSnapshot.hasData
                              ? notifSnapshot.data!.docs.length
                              : 0;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const NotificationsPage()),
                                    );
                                  },
                                  child: Icon(
                                    Icons.notifications_outlined,
                                    color: primaryNavy,
                                    size: 22,
                                  ),
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Main Revenue Card ──────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A1D37), Color(0xFF1A3A5C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primaryNavy.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: gold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: gold,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Total Earnings',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '3% Commission',
                                style: GoogleFonts.inter(
                                  color: Colors.greenAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '\$${_formatCurrency(totalEarnings)}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'From $paidBookings completed transaction${paidBookings == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Stats Grid ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _miniStatCard(
                          'Total Bookings',
                          totalBookings.toString(),
                          Icons.receipt_long_outlined,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _miniStatCard(
                          'Completed',
                          paidBookings.toString(),
                          Icons.check_circle_outline,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _miniStatCard(
                          'Pending',
                          pendingBookings.toString(),
                          Icons.pending_outlined,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Pending Payout Card ─────────────────────────
                  if (pendingAmount > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.hourglass_top_rounded,
                                color: Colors.orange.shade700, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pending Payout',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '\$${_formatCurrency(pendingAmount)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 28),

                  // ── Recent Transactions ─────────────────────────
                  Text(
                    'Recent Transactions',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (recentBookings.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No transactions yet',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Bookings will appear here when buyers pay',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...recentBookings.map((booking) => _transactionTile(
                          booking['propertyTitle'] ?? 'Property',
                          (booking['amount'] as num?)?.toDouble() ?? 0.0,
                          booking['status'] ?? 'unknown',
                          booking['createdAt'] as Timestamp?,
                          booking['paymentMethod'] ?? 'N/A',
                        )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _miniStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0A1D37),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(String title, double amount, String status,
      Timestamp? createdAt, String paymentMethod) {
    final isPaid = status == 'paid';
    final commission = amount * 0.03;
    String timeAgo = '';

    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt.toDate());
      if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = '${diff.inDays}d ago';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPaid
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPaid ? Icons.check_circle : Icons.pending,
              color: isPaid ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFF0A1D37),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$paymentMethod · $timeAgo',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+\$${_formatCurrency(commission)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
              Text(
                status.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isPaid ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
  }
}
