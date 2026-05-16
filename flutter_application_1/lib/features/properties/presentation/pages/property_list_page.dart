import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/properties_bloc.dart';
import '../widgets/property_card.dart';
import '../widgets/filter_bottom_sheet.dart';

class PropertyListPage extends StatelessWidget {
  final bool isGuest;

  const PropertyListPage({super.key, this.isGuest = false});

  @override
  Widget build(BuildContext context) {
    return PropertyListView(isGuest: isGuest);
  }
}

class PropertyListView extends StatelessWidget {
  final bool isGuest;

  const PropertyListView({super.key, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    final Color primaryNavy = const Color(0xFF0A1D37);
    final Color accentGold = const Color(0xFFFFD700);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipPath(
                  clipper: HeaderClipper(),
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    color: primaryNavy,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              'Good morning, John 👋',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Find Your\n',
                                    style: GoogleFonts.playfairDisplay(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Dream Home',
                                    style: GoogleFonts.playfairDisplay(
                                      color: accentGold,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Search Bar overlapping header
                Positioned(
                  bottom: -30,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Icon(Icons.search, color: Colors.grey.shade400, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              onChanged: (value) => context
                                  .read<PropertiesBloc>()
                                  .add(PropertiesSearchQueryChanged(value)),
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: 'Search city, area, property...',
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (bottomSheetContext) => BlocProvider.value(
                                  value: context.read<PropertiesBloc>(),
                                  child: const FilterBottomSheet(),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: primaryNavy,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(Icons.tune, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Browse by Type',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryNavy,
                ),
              ),
            ),

            const SizedBox(height: 16),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _categoryItem('House', const Color(0xFFB85C38), Icons.home),
                  _categoryItem('Villa', const Color(0xFF3E4149), Icons.villa),
                  _categoryItem('Apartment', const Color(0xFF427D9D), Icons.apartment),
                  _categoryItem('Condo', const Color(0xFF916BBF), Icons.business),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Property List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: BlocBuilder<PropertiesBloc, PropertiesState>(
                builder: (context, state) {
                  if (state.status == PropertiesStatus.loading) {
                    return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF0A1D37)));
                  } else if (state.status == PropertiesStatus.success) {
                    if (state.filteredProperties.isEmpty) {
                      return const Center(
                        child: Text('No properties found.'),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.filteredProperties.length,
                      itemBuilder: (context, index) {
                        return PropertyCard(
                          property: state.filteredProperties[index],
                          isGuest: isGuest,
                        );
                      },
                    );
                  } else if (state.status == PropertiesStatus.failure) {
                    return Center(child: Text(state.errorMessage ?? 'Error'));
                  }
                  return const SizedBox();
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _categoryItem(String label, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

