import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/properties/data/models/property.dart';
import 'chat_page.dart';

class AgentInboxPage extends StatefulWidget {
  final String agentEmail;
  const AgentInboxPage({super.key, required this.agentEmail});

  @override
  State<AgentInboxPage> createState() => _AgentInboxPageState();
}

class _AgentInboxPageState extends State<AgentInboxPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final Set<String> _deletedConversations = {};

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF0A1D37);
    const Color gold = Color(0xFFFFD700);

    if (currentUser == null) {
      return const Center(child: Text('Please login to view messages.'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 0,
        title: Text(
          'Messages',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // We query the messages where the agentID matches the current user.
        // We sort by sendAt so we get the latest messages first.
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('agentID', isEqualTo: currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.toList();

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryNavy.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort locally to avoid Firestore composite index requirement
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['sendAt'] as Timestamp?;
            final bTime = bData['sendAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime); // descending
          });

          // Group by conversationID to only show the latest message for each conversation
          final Map<String, Map<String, dynamic>> conversations = {};
          
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final deletedBy = List<String>.from(data['deletedBy'] ?? []);
            if (deletedBy.contains(currentUser!.uid)) continue;
            
            final convId = data['conversationID'] as String?;
            if (convId != null && !conversations.containsKey(convId) && !_deletedConversations.contains(convId)) {
              conversations[convId] = data;
            }
          }

          final inboxItems = conversations.values.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: inboxItems.length,
            itemBuilder: (context, index) {
              final data = inboxItems[index];
              final String text = data['lastMessage'] ?? data['text'] ?? 'No message';
              final Timestamp? time = data['lastMessageAt'] ?? data['sendAt'];
              final String senderId = data['senderID'] ?? '';
              final bool isUnread = (data['isRead'] == false) && (senderId != currentUser!.uid);
              final String buyerId = data['buyerID'] ?? '';
              final String propertyId = data['propertyID'] ?? '';
              final String convId = data['conversationID'] ?? '';

              // Format time
              String timeStr = '';
              if (time != null) {
                final date = time.toDate();
                timeStr = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
              }

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('Users').doc(buyerId).snapshots(),
                builder: (context, userSnapshot) {
                  String buyerName = 'Buyer Inquiring';
                  String? buyerPhoto;
                  
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (userData != null) {
                      final first = userData['firstname'] ?? '';
                      final last = userData['lastname'] ?? '';
                      final full = '$first $last'.trim();
                      if (full.isNotEmpty) buyerName = full;
                      buyerPhoto = userData['profileImageUrl'] as String?;
                    }
                  }
                  final initials = buyerName.isNotEmpty ? buyerName[0].toUpperCase() : '?';

                  return Dismissible(
                    key: Key(convId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) async {
                      setState(() {
                        _deletedConversations.add(convId);
                      });
                      try {
                        final query = await FirebaseFirestore.instance
                            .collection('messages')
                            .where('conversationID', isEqualTo: convId)
                            .get();
                        for (var doc in query.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final deletedBy = List<String>.from(data['deletedBy'] ?? []);
                          if (!deletedBy.contains(currentUser!.uid)) {
                            deletedBy.add(currentUser!.uid);
                            await doc.reference.update({'deletedBy': deletedBy});
                          }
                        }
                      } catch (e) {
                        debugPrint('Error deleting conversation: $e');
                      }
                    },
                    child: GestureDetector(
                      onTap: () {
                      _navigateToChat(context, convId, buyerId, propertyId);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                        border: isUnread ? Border.all(color: gold.withOpacity(0.5), width: 1.5) : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: primaryNavy.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: buyerPhoto != null && buyerPhoto.isNotEmpty
                                ? Image.network(buyerPhoto, fit: BoxFit.cover)
                                : Center(
                                    child: Text(
                                      initials,
                                      style: GoogleFonts.playfairDisplay(
                                        color: primaryNavy,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('Properties').doc(propertyId).get(),
                              builder: (context, propSnapshot) {
                                String propertyTitle = 'Property Listing';
                                if (propSnapshot.hasData && propSnapshot.data!.exists) {
                                  final propData = propSnapshot.data!.data() as Map<String, dynamic>?;
                                  if (propData != null) {
                                    propertyTitle = propData['Title'] ?? propData['title'] ?? 'Property Listing';
                                  }
                                } else if (propSnapshot.connectionState == ConnectionState.done) {
                                  propertyTitle = 'Deleted Listing';
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            buyerName,
                                            style: GoogleFonts.inter(
                                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                              fontSize: 15,
                                              color: primaryNavy,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          timeStr,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: isUnread ? gold : Colors.grey.shade500,
                                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Listing: $propertyTitle',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: isUnread ? primaryNavy : Colors.grey.shade600,
                                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 12),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToChat(BuildContext context, String? convId, String buyerId, String propertyId) async {
    // 1. Mark as read
    // For simplicity, we assume we want to mark the latest message as read.
    // In a production app, you'd mark all unread messages in this conversation.

    // 2. We need a Property object to pass to ChatPage.
    // Fetch it from Firestore
    try {
      final doc = await FirebaseFirestore.instance.collection('Properties').doc(propertyId).get();
      Property property;
      
      if (doc.exists) {
        property = Property.fromFirestore(doc);
      } else {
        // Fallback: If property was deleted, create a dummy one so chat still works
        property = Property(
          id: propertyId.isEmpty ? 'unknown' : propertyId,
          agentID: FirebaseAuth.instance.currentUser?.uid ?? '',
          title: 'Deleted/Unknown Property',
          description: 'This property listing is no longer available.',
          price: 0,
          type: PropertyType.house,
          status: PropertyStatus.sold,
          location: 'Unknown Location',
          imageUrls: const [],
          bedrooms: 0,
          bathrooms: 0,
          floorArea: 0,
        );
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              property: property,
              existingConversationId: convId,
              buyerId: buyerId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat: $e')),
        );
      }
    }
  }
}
