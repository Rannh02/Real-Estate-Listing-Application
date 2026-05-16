import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/login/presentation/pages/login_page.dart';
import '../../data/models/property.dart';
import '../../bloc/properties_bloc.dart';

class PropertyDetailsPage extends StatelessWidget {
  final Property property;
  final bool isGuest;

  const PropertyDetailsPage({
    super.key,
    required this.property,
    this.isGuest = false,
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
              if (!isGuest)
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
                                  '${currentProperty.bathrooms} Bathrooms'),
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
                      onPressed: () {
                        if (isGuest) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Booking request sent!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        isGuest ? 'Login to Book' : 'Book Now',
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
}

