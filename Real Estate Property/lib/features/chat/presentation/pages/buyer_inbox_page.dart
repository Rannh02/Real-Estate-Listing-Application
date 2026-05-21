import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/properties/data/models/property.dart';
import 'chat_page.dart';

class BuyerInboxPage extends StatefulWidget {
  final bool isGuest;
  
  const BuyerInboxPage({super.key, required this.isGuest});

  @override
  State<BuyerInboxPage> createState() => _BuyerInboxPageState();
}

class _BuyerInboxPageState extends State<BuyerInboxPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final Set<String> _deletedConversations = {};

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF0A1D37);
    const Color gold = Color(0xFFFFD700);

    if (widget.isGuest || currentUser == null) {
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
        body: Center(
          child: Text(
            'Please login to view messages.',
            style: GoogleFonts.inter(fontSize: 16, color: primaryNavy),
          ),
        ),
      );
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
        // We query the messages where the buyerID matches the current user.
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('buyerID', isEqualTo: currentUser!.uid)
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
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return -1;
            if (bTime == null) return 1;
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
              
              // Determine if it's unread from the buyer's perspective.
              final String senderId = data['senderID'] ?? '';
              final bool isUnread = (data['isRead'] == false) && (senderId != currentUser!.uid);
              
              final String propertyId = data['propertyID'] ?? '';
              final String convId = data['conversationID'] ?? '';
              final String agentId = data['agentID'] ?? '';

              // Format time
              String timeStr = '';
              if (time != null) {
                final date = time.toDate();
                timeStr = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
              }

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('Users').doc(agentId).snapshots(),
                builder: (context, userSnapshot) {
                  String agentName = 'EstateX Agent';
                  String? agentPhoto;
                  
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (userData != null) {
                      final first = userData['firstname'] ?? '';
                      final last = userData['lastname'] ?? '';
                      final full = '$first $last'.trim();
                      if (full.isNotEmpty) agentName = full;
                      agentPhoto = userData['profileImageUrl'] as String?;
                    }
                  }
                  final initials = agentName.isNotEmpty ? agentName[0].toUpperCase() : '?';

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
                      _navigateToChat(context, convId, propertyId);
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
                            child: agentPhoto != null && agentPhoto.isNotEmpty
                                ? Image.network(agentPhoto, fit: BoxFit.cover)
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
                                 String statusString = '';
                                 String displayTitle = propertyTitle;
                                 if (propSnapshot.hasData && propSnapshot.data!.exists) {
                                   final propData = propSnapshot.data!.data() as Map<String, dynamic>?;
                                   if (propData != null) {
                                     propertyTitle = propData['Title'] ?? propData['title'] ?? 'Property Listing';
                                     statusString = propData['Status'] ?? propData['status'] ?? '';
                                     displayTitle = propertyTitle;
                                     if (statusString.toLowerCase() == 'sold') {
                                       displayTitle = '$propertyTitle (Sold)';
                                     }
                                   }
                                 } else if (propSnapshot.connectionState == ConnectionState.done) {
                                   propertyTitle = 'Deleted Listing';
                                   displayTitle = propertyTitle;
                                 }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            agentName,
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
                                      'Listing: $displayTitle',
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

  void _navigateToChat(BuildContext context, String? convId, String propertyId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('Properties').doc(propertyId).get();
      Property property;
      
      if (doc.exists) {
        property = Property.fromFirestore(doc);
      } else {
        // Fallback dummy property
        property = Property(
          id: propertyId.isEmpty ? 'unknown' : propertyId,
          agentID: 'unknown',
          title: 'Deleted Property',
          description: 'This property is no longer available.',
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
              // Buyer side doesn't need to pass buyerId because it defaults to currentUser
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
