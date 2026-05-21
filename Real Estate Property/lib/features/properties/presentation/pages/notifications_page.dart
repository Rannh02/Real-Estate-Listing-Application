import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/properties/data/models/property.dart';
import 'package:flutter_application_1/features/chat/presentation/pages/chat_page.dart';
import 'property_details_page.dart';

class NotificationService {
  static Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    String? referenceId,
    String? referenceType,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('Notifications').doc();
      await docRef.set({
        'notificationID': docRef.id,
        'recipientID': recipientId,
        'Title': title,
        'Body': body,
        'Type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'referenceID': referenceId ?? '',
        'referenceType': referenceType ?? '',
      });
    } catch (e) {
      // Ignore background notification creation failures to not interrupt main flow
    }
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _currentUser = FirebaseAuth.instance.currentUser;
  static const Color primaryNavy = Color(0xFF0A1D37);
  static const Color gold = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _markAllAsRead();
  }

  void _markAllAsRead() async {
    final uid = _currentUser?.uid;
    if (uid != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('Notifications')
            .where('recipientID', isEqualTo: uid)
            .where('isRead', isEqualTo: false)
            .get();
        if (snapshot.docs.isNotEmpty) {
          final batch = FirebaseFirestore.instance.batch();
          for (var doc in snapshot.docs) {
            batch.update(doc.reference, {'isRead': true});
          }
          await batch.commit();
        }
      } catch (e) {
        // ignore
      }
    }
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> data) async {
    final refType = data['referenceType'] as String?;
    final refId = data['referenceID'] as String?;

    if (refId == null || refId.isEmpty) return;

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: gold)),
    );

    try {
      if (refType == 'conversation') {
        // Find property ID and buyer ID from conversation ID (format: propertyId_buyerId)
        final parts = refId.split('_');
        if (parts.length >= 2) {
          final propertyId = parts[0];
          final buyerId = parts[1];

          final propDoc = await FirebaseFirestore.instance.collection('Properties').doc(propertyId).get();
          if (propDoc.exists && context.mounted) {
            final property = Property.fromFirestore(propDoc);
            Navigator.pop(context); // Close loading dialog
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  property: property,
                  existingConversationId: refId,
                  buyerId: buyerId,
                ),
              ),
            );
            return;
          }
        }
      } else if (refType == 'property') {
        final propDoc = await FirebaseFirestore.instance.collection('Properties').doc(refId).get();
        if (propDoc.exists && context.mounted) {
          final property = Property.fromFirestore(propDoc);
          Navigator.pop(context); // Close loading dialog
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailsPage(property: property),
            ),
          );
          return;
        }
      }
    } catch (e) {
      // ignore
    }

    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open related listing or chat.')),
      );
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'agent_approval':
        return Icons.verified_user_rounded;
      case 'agent_rejection':
        return Icons.gavel_rounded;
      case 'listing_status':
        return Icons.home_work_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'agent_approval':
        return Colors.green.shade600;
      case 'agent_rejection':
        return Colors.red.shade600;
      case 'listing_status':
        return Colors.blue.shade600;
      case 'message':
        return gold;
      default:
        return primaryNavy;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text('Notifications', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primaryNavy)),
          centerTitle: true,
        ),
        body: Center(
          child: Text('Please log in to view notifications.', style: GoogleFonts.inter(color: Colors.grey)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Notifications', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: primaryNavy)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryNavy),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear all notifications',
            onPressed: () async {
              if (_currentUser == null) return;
              try {
                final snapshot = await FirebaseFirestore.instance
                    .collection('Notifications')
                    .where('recipientID', isEqualTo: _currentUser!.uid)
                    .get();
                if (snapshot.docs.isEmpty) return;
                
                final batch = FirebaseFirestore.instance.batch();
                for (var doc in snapshot.docs) {
                  batch.delete(doc.reference);
                }
                await batch.commit();
              } catch (e) {
                // ignore
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Notifications')
            .where('recipientID', isEqualTo: _currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading notifications', style: GoogleFonts.inter(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryNavy));
          }

          final docs = snapshot.data?.docs.toList() ?? [];
          
          // Sort locally to prevent Firestore composite index missing error
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return -1;
            if (bTime == null) return 1;
            return bTime.compareTo(aTime); // descending
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['Title'] ?? 'Notification';
              final body = data['Body'] ?? '';
              final type = data['Type'] ?? '';
              final isRead = data['isRead'] ?? false;
              final timestamp = data['createdAt'] as Timestamp?;

              String timeStr = '';
              if (timestamp != null) {
                final date = timestamp.toDate();
                timeStr = '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
              }

              final iconColor = _getColorForType(type);
              final icon = _getIconForType(type);

              return GestureDetector(
                onTap: () => _handleNotificationTap(context, data),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: !isRead ? Border.all(color: iconColor.withOpacity(0.3), width: 1.5) : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: !isRead ? FontWeight.bold : FontWeight.w600,
                                      color: primaryNavy,
                                    ),
                                  ),
                                ),
                                Text(
                                  timeStr,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              body,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
