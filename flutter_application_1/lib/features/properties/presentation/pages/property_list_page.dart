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
    return BlocProvider(
      create: (context) => PropertiesBloc()..add(PropertiesFetchStarted()),
      child: PropertyListView(isGuest: isGuest),
    );
  }
}

class PropertyListView extends StatelessWidget {
  final bool isGuest;

  const PropertyListView({super.key, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find your',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Dream Home',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) => context.read<PropertiesBloc>().add(PropertiesSearchQueryChanged(value)),
                        decoration: InputDecoration(
                          hintText: 'Search properties...',
                          prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
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
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.tune, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Expanded(
                child: BlocBuilder<PropertiesBloc, PropertiesState>(
                  builder: (context, state) {
                    if (state.status == PropertiesStatus.loading) {
                      return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
                    } else if (state.status == PropertiesStatus.success) {
                      if (state.filteredProperties.isEmpty) {
                        return const Center(
                          child: Text('No properties found matching your criteria.'),
                        );
                      }
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: state.filteredProperties.length,
                        itemBuilder: (context, index) {
                          return PropertyCard(
                            property: state.filteredProperties[index],
                            isGuest: isGuest,
                          );
                        },
                      );
                    } else if (state.status == PropertiesStatus.failure) {
                      return Center(child: Text(state.errorMessage ?? 'An error occurred'));
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
