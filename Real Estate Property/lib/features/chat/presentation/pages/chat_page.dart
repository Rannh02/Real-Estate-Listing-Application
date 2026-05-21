import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/properties/data/models/property.dart';
import 'package:flutter_application_1/features/properties/presentation/pages/notifications_page.dart';

class ChatPage extends StatefulWidget {
  final Property property;
  final String? existingConversationId;
  final String? buyerId; // For agent replying to a buyer

  const ChatPage({
    super.key,
    required this.property,
    this.existingConversationId,
    this.buyerId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;

  late String _conversationId;
  late String _actualBuyerId;

  @override
  void initState() {
    super.initState();
    // If agent is replying, buyerId is passed. Otherwise, current user is the buyer.
    _actualBuyerId = widget.buyerId ?? currentUser?.uid ?? 'guest';
    final existingId = widget.existingConversationId;
    _conversationId = (existingId != null && existingId.isNotEmpty)
        ? existingId
        : '${widget.property.id}_$_actualBuyerId';
  }

  void _sendNotificationInBackground(String text, String recipientId) async {
    try {
      final senderDoc = await FirebaseFirestore.instance.collection('Users').doc(currentUser!.uid).get();
      String senderName = 'Someone';
      if (senderDoc.exists) {
        final data = senderDoc.data();
        if (data != null) {
          final first = data['firstname'] ?? '';
          final last = data['lastname'] ?? '';
          senderName = '$first $last'.trim();
        }
      }
      if (senderName.isEmpty) {
        senderName = currentUser!.displayName ?? 'User';
      }

      await NotificationService.sendNotification(
        recipientId: recipientId,
        title: 'New Message',
        body: '$senderName: $text',
        type: 'message',
        referenceId: _conversationId,
        referenceType: 'conversation',
      );
    } catch (e) {
      // ignore
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    _messageController.clear();

    final messageId = FirebaseFirestore.instance.collection('messages').doc().id;

    // Using the exact schema provided by the user
    final messageData = {
      'agentID': widget.property.agentID,
      'buyerID': _actualBuyerId,
      'conversationID': _conversationId,
      'imageURL': currentUser!.photoURL ?? '',
      'isRead': false,
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'messageID': messageId,
      'propertyID': widget.property.id,
      'sendAt': FieldValue.serverTimestamp(),
      'senderID': currentUser!.uid,
      'text': text,
    };

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(messageId)
        .set(messageData);

    final isAgent = currentUser!.uid == widget.property.agentID;
    final recipientId = isAgent ? _actualBuyerId : widget.property.agentID;
    _sendNotificationInBackground(text, recipientId);

    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryNavy = const Color(0xFF0A1D37);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Please login to use chat.')),
      );
    }

    final isAgent = currentUser!.uid == widget.property.agentID;
    final otherUserId = isAgent ? _actualBuyerId : widget.property.agentID;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryNavy),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('Users').doc(otherUserId).snapshots(),
          builder: (context, userSnapshot) {
            String name = isAgent ? 'Buyer' : 'EstateX Agent';
            String? photoUrl;
            
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              if (userData != null) {
                final String first = userData['firstname'] ?? '';
                final String last = userData['lastname'] ?? '';
                final String full = '$first $last'.trim();
                if (full.isNotEmpty) {
                  name = full;
                } else {
                  name = userData['Email']?.split('@')[0] ?? name;
                }
                photoUrl = userData['profileImageUrl'] as String?;
              }
            }
            
            final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

            return Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryNavy,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(photoUrl, fit: BoxFit.cover)
                      : Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          color: primaryNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Property: ${widget.property.title}',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('conversationID', isEqualTo: _conversationId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading chat: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!.docs.toList();
                final messages = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final deletedBy = List<String>.from(data['deletedBy'] ?? []);
                  return !deletedBy.contains(currentUser!.uid);
                }).toList();
                
                // Sort locally to avoid Firestore composite index requirement
                messages.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['sendAt'] as Timestamp?;
                  final bTime = bData['sendAt'] as Timestamp?;
                  
                  // null timestamp means it's a pending local write (brand new message)
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return -1; // Put newest at the top (index 0)
                  if (bTime == null) return 1;
                  
                  return bTime.compareTo(aTime); // descending
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Send a message to start the conversation!',
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Show newest at the bottom
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderID'] == currentUser!.uid;
                    final text = data['text'] ?? '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? primaryNavy : Colors.white,
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                            bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          text,
                          style: GoogleFonts.inter(
                            color: isMe ? Colors.white : primaryNavy,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.inter(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryNavy,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
