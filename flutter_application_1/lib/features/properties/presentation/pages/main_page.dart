import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/properties_bloc.dart';
import 'property_list_page.dart';
import 'profile_page.dart';
import 'saved_list_page.dart';

class MainPage extends StatefulWidget {
  final bool isGuest;
  final String? email;

  const MainPage({
    super.key,
    required this.isGuest,
    this.email,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      PropertyListPage(isGuest: widget.isGuest),
      SavedListPage(isGuest: widget.isGuest),
      const _PlaceholderPage(title: 'Search Properties', icon: Icons.search),
      const _PlaceholderPage(title: 'Notifications', icon: Icons.notifications_none),
      ProfilePage(isGuest: widget.isGuest, email: widget.email),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryNavy = const Color(0xFF0A1D37);

    return BlocProvider(
      create: (context) => PropertiesBloc()..add(PropertiesFetchStarted()),
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildNavBarItem(0, Icons.home_filled, Icons.home_outlined, 'Home')),
              Expanded(child: _buildNavBarItem(1, Icons.favorite, Icons.favorite_border, 'Saved')),
              _buildSearchButton(),
              Expanded(child: _buildNavBarItem(3, Icons.notifications, Icons.notifications_none, 'Notifications')),
              Expanded(child: _buildNavBarItem(4, Icons.person, Icons.person_outline, 'Profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final bool isSelected = _selectedIndex == index;
    final Color primaryNavy = const Color(0xFF0A1D37);

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : inactiveIcon,
            color: isSelected ? primaryNavy : Colors.grey.shade400,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? primaryNavy : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    final bool isSelected = _selectedIndex == 2;
    final Color primaryNavy = const Color(0xFF0A1D37);

    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: primaryNavy,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryNavy.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.search,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderPage({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF0A1D37))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'Your $title will appear here',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


