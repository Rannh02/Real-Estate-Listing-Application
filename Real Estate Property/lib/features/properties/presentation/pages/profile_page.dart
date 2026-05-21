import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_application_1/features/login/presentation/pages/login_page.dart';
import 'notifications_page.dart';

class ProfilePage extends StatefulWidget {
  final bool isGuest;
  final String? email;

  const ProfilePage({
    super.key,
    required this.isGuest,
    this.email,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color primaryNavy = Color(0xFF0A1D37);
  static const Color gold = Color(0xFFFFD700);

  bool _isUploadingPhoto = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _changeProfilePhoto() async {
    if (widget.isGuest) return;

    final source = await _showSourceDialog();
    if (source == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final uid = _uid!;
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      // Upload file using putData instead of putFile for Windows compatibility
      final bytes = await picked.readAsBytes();
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putData(bytes, metadata);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('Users').doc(uid).update({
        'profileImageUrl': url,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!')),
        );
      }
    } on FirebaseException catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        final msg = e.code == 'object-not-found' || e.code == 'storage/object-not-found'
            ? 'Firebase Storage is not enabled. Please activate it in the Firebase console.'
            : 'Storage error: ${e.message ?? e.code}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e')),
        );
      }
    }
  }

  Future<ImageSource?> _showSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Photo',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Update your profile photo',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _sourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _sourceOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: primaryNavy),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: primaryNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isGuest) {
      return _buildGuestProfile();
    }

    // Use real-time stream for logged-in users so profile photo updates instantly
    final uid = _uid;
    if (uid == null) return _buildGuestProfile();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F9FA),
            body: Center(
              child: CircularProgressIndicator(color: primaryNavy),
            ),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        return _buildProfile(data, uid);
      },
    );
  }

  Widget _buildGuestProfile() => _buildProfile(null, null);

  Widget _buildProfile(Map<String, dynamic>? data, String? uid) {
    final String firstName = data?['firstname'] ?? '';
    final String lastName = data?['lastname'] ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final String displayName = widget.isGuest
        ? 'Guest Explorer'
        : (fullName.isNotEmpty ? fullName : (widget.email?.split('@')[0] ?? 'User'));

    final String displayEmail = widget.isGuest
        ? 'Browse and save properties'
        : (widget.email ?? data?['Email'] ?? '');

    final String phoneNumber = data?['phoneNumber'] ?? 'Not provided';

    final String? rawPhotoUrl = data?['profileImageUrl'] as String?;
    final String? photoUrl = (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty)
        ? rawPhotoUrl
        : null;

    final String middleName = data?['middlename'] ?? '';
    final String fullNameWithMiddle =
        '$firstName${middleName.isNotEmpty ? ' $middleName' : ''} $lastName'.trim();

    final String initials = widget.isGuest
        ? 'G'
        : (displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Top Banner ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 60),
                decoration: const BoxDecoration(
                  color: primaryNavy,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: _changeProfilePhoto,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: gold,
                              border: Border.all(
                                color: gold.withOpacity(0.6),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: gold.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _isUploadingPhoto
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _buildAvatar(photoUrl, initials),
                          ),
                          if (!widget.isGuest)
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryNavy, width: 2),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: primaryNavy,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName.isEmpty ? 'User' : displayName,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayEmail,
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: gold.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isGuest ? Icons.explore : Icons.verified,
                            color: gold,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isGuest ? 'Guest Access' : 'Verified Buyer',
                            style: GoogleFonts.inter(
                              color: gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.isGuest)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: TextButton.icon(
                          onPressed: _changeProfilePhoto,
                          icon: Icon(
                            photoUrl != null ? Icons.edit_rounded : Icons.add_a_photo_rounded,
                            size: 14,
                            color: Colors.white54,
                          ),
                          label: Text(
                            photoUrl != null ? 'Change photo' : 'Add profile photo',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Activity Stats ──────────────────────────────────────────
              _buildStatsSection(uid),

              const SizedBox(height: 24),

              // ── Personal Info card ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _infoRow(
                        Icons.person_outline,
                        'Full Name',
                        fullNameWithMiddle.isNotEmpty ? fullNameWithMiddle : 'Not provided',
                      ),
                      Divider(height: 1, color: Colors.grey.shade100),
                      _infoRow(
                        Icons.email_outlined,
                        'Email Address',
                        widget.email ?? data?['Email'] ?? 'Not provided',
                      ),
                      Divider(height: 1, color: Colors.grey.shade100),
                      _infoRow(Icons.phone_outlined, 'Phone Number', phoneNumber),
                      Divider(height: 1, color: Colors.grey.shade100),
                      GestureDetector(
                        onTap: () {
                          if (!widget.isGuest) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsPage()),
                            );
                          }
                        },
                        child: _infoRow(Icons.notifications_none, 'Notifications', widget.isGuest ? 'Disabled' : 'View Alerts'),
                      ),
                      Divider(height: 1, color: Colors.grey.shade100),
                      _infoRow(Icons.security, 'Security', 'Password & Biometrics'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Action Button ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: widget.isGuest
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryNavy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Sign In for Full Access',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: Text(
                            'Log Out',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the avatar image, with a direct Image.network (no cache) + initials fallback.
  Widget _buildAvatar(String? photoUrl, String initials) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Center(
        child: Text(
          initials,
          style: GoogleFonts.playfairDisplay(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: primaryNavy,
          ),
        ),
      );
    }

    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      width: 100,
      height: 100,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: Text(
            initials,
            style: GoogleFonts.playfairDisplay(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: primaryNavy,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stack) {
        return Center(
          child: Text(
            initials,
            style: GoogleFonts.playfairDisplay(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: primaryNavy,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection(String? uid) {
    if (uid == null) {
      return _statsContainer('0', '0', '0');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('SavedProperties').where('buyerID', isEqualTo: uid).snapshots(),
      builder: (context, savedSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('bookings').where('buyerId', isEqualTo: uid).snapshots(),
          builder: (context, bookingsSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('messages').where('buyerID', isEqualTo: uid).snapshots(),
              builder: (context, messagesSnapshot) {
                
                final favCount = savedSnapshot.hasData ? savedSnapshot.data!.docs.length.toString() : '...';
                final recentCount = bookingsSnapshot.hasData ? bookingsSnapshot.data!.docs.length.toString() : '...';
                
                String inqCount = '...';
                if (messagesSnapshot.hasData) {
                  final Set<String> conversations = {};
                  for (var doc in messagesSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final agentId = data['agentID'] as String?;
                    final propertyId = data['propertyID'] as String?;
                    if (agentId != null && propertyId != null) {
                      conversations.add('${agentId}_$propertyId');
                    }
                  }
                  inqCount = conversations.length.toString();
                }

                return _statsContainer(favCount, recentCount, inqCount);
              }
            );
          }
        );
      }
    );
  }

  Widget _statsContainer(String fav, String recent, String inq) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat(fav, 'Favorites', Icons.favorite_border, Colors.red.shade400),
            Container(width: 1, height: 40, color: Colors.grey.shade200),
            _stat(recent, 'Recent', Icons.history, primaryNavy),
            Container(width: 1, height: 40, color: Colors.grey.shade200),
            _stat(inq, 'Inquiries', Icons.chat_bubble_outline, Colors.blue.shade600),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: primaryNavy,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryNavy),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: primaryNavy,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
