import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/properties_bloc.dart';
import '../widgets/property_card.dart';

class SavedListPage extends StatelessWidget {
  final bool isGuest;

  const SavedListPage({super.key, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    final Color primaryNavy = const Color(0xFF0A1D37);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Saved Properties',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: primaryNavy,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<PropertiesBloc, PropertiesState>(
        builder: (context, state) {
          final savedProperties = state.properties.where((p) => p.isSaved).toList();

          if (savedProperties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey[200]),
                  const SizedBox(height: 16),
                  Text(
                    'No saved properties yet',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on any property to save it.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: savedProperties.length,
            itemBuilder: (context, index) {
              return PropertyCard(
                property: savedProperties[index],
                isGuest: isGuest,
              );
            },
          );
        },
      ),
    );
  }
}
