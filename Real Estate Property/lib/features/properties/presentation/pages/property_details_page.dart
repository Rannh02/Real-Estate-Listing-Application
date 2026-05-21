import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/login/presentation/pages/login_page.dart';
import 'package:flutter_application_1/features/payment/presentation/pages/payment_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/property.dart';
import '../../bloc/properties_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyDetailsPage extends StatelessWidget {
  final Property property;
  final bool isGuest;
  final bool isAgentMode;

  const PropertyDetailsPage({
    super.key,
    required this.property,
    this.isGuest = false,
    this.isAgentMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryNavy = const Color(0xFF0A1D37);
    final Color accentGold = const Color(0xFFFFD700);

    return BlocBuilder<PropertiesBloc, PropertiesState>(
      builder: (context, state) {
        // Get the latest property state from the bloc
        final currentProperty = state.properties.firstWhere(
          (p) => p.id == property.id,
          orElse: () => property,
        );

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
               // Background Image
               Positioned(
                 top: 0,
                 left: 0,
                 right: 0,
                 height: MediaQuery.of(context).size.height * 0.45,
                 child: Hero(
                   tag: 'property-image-${currentProperty.id}',
                   child: CachedNetworkImage(
                     imageUrl: currentProperty.imageUrl,
                     fit: BoxFit.cover,
                   ),
                 ),
               ),
               // Sold Out badge
               if (currentProperty.status == PropertyStatus.sold)
                 Positioned(
                   top: 20,
                   left: 20,
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: Colors.black54,
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Text(
                       'Sold Out',
                       style: GoogleFonts.inter(
                         color: Colors.white,
                         fontWeight: FontWeight.bold,
                         fontSize: 14,
                       ),
                     ),
                   ),
                 ),

              // Back Button
              Positioned(
                top: 50,
                left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(Icons.arrow_back_ios_new, size: 20, color: primaryNavy),
                  ),
                ),
              ),

              // Favorite Button
              if (!isGuest && !isAgentMode)
                Positioned(
                  top: 50,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      context.read<PropertiesBloc>().add(PropertiesToggleSave(currentProperty.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(currentProperty.isSaved
                              ? 'Removed from saved'
                              : 'Added to saved!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        currentProperty.isSaved ? Icons.favorite : Icons.favorite_border,
                        color: currentProperty.isSaved ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),

              // Content
              DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.6,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: primaryNavy.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  currentProperty.type.name[0].toUpperCase() +
                                      currentProperty.type.name.substring(1),
                                  style: GoogleFonts.inter(
                                    color: primaryNavy,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.remove_red_eye_outlined, color: accentGold, size: 22),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${currentProperty.viewCount} views',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: primaryNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            currentProperty.title,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.grey.shade400, size: 20),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  currentProperty.location,
                                  style: GoogleFonts.inter(
                                      color: Colors.grey.shade500, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _facilityItem(Icons.king_bed_outlined,
                                  '${currentProperty.bedrooms} Bedrooms'),
                              _facilityItem(Icons.bathtub_outlined,
                                  '${currentProperty.bathrooms.toString().replaceAll(RegExp(r'\\.0$'), '')} Bathrooms'),
                              _facilityItem(Icons.square_foot_outlined,
                                  '${currentProperty.floorArea} m²'),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Text(
                            'Description',
                            style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: primaryNavy),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentProperty.description,
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            'Location',
                            style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: primaryNavy),
                          ),
                          const SizedBox(height: 16),
                          // Embedded map
                          Container(
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  currentProperty.latitude ?? 14.5995,
                                  currentProperty.longitude ?? 120.9842,
                                ),
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('property_loc'),
                                  position: LatLng(
                                    currentProperty.latitude ?? 14.5995,
                                    currentProperty.longitude ?? 120.9842,
                                  ),
                                  infoWindow: InfoWindow(
                                    title: currentProperty.title,
                                    snippet: currentProperty.location,
                                  ),
                                ),
                              },
                              myLocationButtonEnabled: false,
                              mapToolbarEnabled: false,
                              zoomControlsEnabled: false,
                              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                                Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                                ),
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Address + View Map button
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.grey.shade400, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  currentProperty.location,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _openGoogleMaps(
                                  currentProperty.latitude,
                                  currentProperty.longitude,
                                  currentProperty.location,
                                ),
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: Text(
                                  'View Map',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryNavy,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Text(
                            'Contact Agent',
                            style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: primaryNavy),
                          ),
                          const SizedBox(height: 16),
                          _buildAgentContactCard(context, currentProperty),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Price',
                        style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        '\$${currentProperty.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},")}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: this.isAgentMode || currentProperty.status == PropertyStatus.sold
                          ? null // Disabled for agents or sold
                          : () {
                              if (this.isGuest) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const LoginPage()),
                                  (route) => false,
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentPage(property: currentProperty),
                                  ),
                                ).then((_) {
                                  if (context.mounted) {
                                    context.read<PropertiesBloc>().add(PropertiesFetchStarted());
                                  }
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: this.isAgentMode ? Colors.grey : primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                      ),
                      child: Text(
                        this.isAgentMode ? 'Not Available' : (this.isGuest ? 'Login to Book' : 'Book Now'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _facilityItem(IconData icon, String label) {
    final Color primaryNavy = const Color(0xFF0A1D37);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryNavy, size: 24),
          const SizedBox(height: 10),
          Text(
            label.split(' ')[0],
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primaryNavy,
            ),
          ),
          Text(
            label.split(' ')[1],
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentContactCard(BuildContext context, Property currentProperty) {
    final Color primaryNavy = const Color(0xFF0A1D37);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('Users').doc(currentProperty.agentID).get(),
            builder: (context, snapshot) {
              String agentName = 'EstateX Agent';
              if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data != null) {
                  final first = data['firstname'] ?? '';
                  final last = data['lastname'] ?? '';
                  if (first.isNotEmpty) {
                    agentName = '$first $last'.trim();
                  }
                }
              }

              return Row(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: primaryNavy,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryNavy.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        agentName.isNotEmpty ? agentName[0].toUpperCase() : 'A',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agentName,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryNavy.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Verified Specialist',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionIconButton(
                icon: Icons.chat_bubble_outline,
                label: 'Chat Agent',
                color: this.isAgentMode ? Colors.grey : const Color(0xFF2196F3),
                onTap: this.isAgentMode || currentProperty.status == PropertyStatus.sold ? null : () {
                  if (currentProperty.id.isEmpty) return; // Guard
                  if (this.isGuest) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(property: currentProperty),
                      ),
                    );
                  }
                },
              ),
              _actionIconButton(
                icon: Icons.email_outlined,
                label: 'Email',
                color: this.isAgentMode ? Colors.grey : const Color(0xFFFF9800),
                onTap: this.isAgentMode || currentProperty.status == PropertyStatus.sold ? null : () => _launchURL(
                  'mailto:agent@estatex.com?subject=Inquiry about ${currentProperty.title}&body=Hello, I am interested in this property.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionIconButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: onTap == null ? Colors.grey.shade200 : color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1D37),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }

  Future<void> _openGoogleMaps(
    double? latitude,
    double? longitude,
    String address,
  ) async {
    Uri mapUri;
    if (latitude != null && longitude != null) {
      // Open to exact coordinates with a pin
      mapUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
    } else {
      // Fall back to searching by address text
      final encoded = Uri.encodeComponent(address);
      mapUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encoded',
      );
    }
    if (!await launchUrl(mapUri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not open Google Maps for: $address');
    }
  }
}

