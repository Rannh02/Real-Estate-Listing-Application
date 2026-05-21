import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/property.dart';
import '../../bloc/properties_bloc.dart';
import '../pages/property_details_page.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final bool isGuest;
  final bool isAgentMode;

  const PropertyCard({
    super.key,
    required this.property,
    this.isGuest = false,
    this.isAgentMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryNavy = const Color(0xFF0A1D37);
    return GestureDetector(
      onTap: () {
        final bloc = context.read<PropertiesBloc>();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: PropertyDetailsPage(
                property: property,
                isGuest: isGuest,
                isAgentMode: isAgentMode,
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  child: CachedNetworkImage(
                    imageUrl: property.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 220,
                      color: Colors.grey[100],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 220,
                      color: Colors.grey[100],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
                // Sold Out badge
                if (property.status == PropertyStatus.sold)
                  Positioned(
                    top: 15,
                    left: 15,
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
                // Heart Icon (Save button)
                if (!isGuest && !isAgentMode && property.status != PropertyStatus.sold)
                  Positioned(
                    top: 15,
                    left: 15,
                    child: GestureDetector(
                      onTap: () {
                        context.read<PropertiesBloc>().add(PropertiesToggleSave(property.id));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          property.isSaved ? Icons.favorite : Icons.favorite_border,
                          color: property.isSaved ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      '\$${property.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},")}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: primaryNavy,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.title,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: primaryNavy,
                              ),
                            ),
                            if (property.caption != null && property.caption!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  property.caption!,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye_outlined, color: Color(0xFFFFD700), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${property.viewCount}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey.shade400, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _infoItem(Icons.king_bed_outlined, '${property.bedrooms} Beds'),
                        _infoItem(Icons.bathtub_outlined, '${property.bathrooms.toString().replaceAll(RegExp(r'\\.0$'), '')} Baths'),
                        _infoItem(Icons.square_foot_outlined, '${property.floorArea} m²'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label) {
    final Color primaryNavy = const Color(0xFF0A1D37);
    return Row(
      children: [
        Icon(icon, color: primaryNavy, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

