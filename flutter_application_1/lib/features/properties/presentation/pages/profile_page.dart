import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/login/presentation/pages/login_page.dart';

class ProfilePage extends StatelessWidget {
  final bool isGuest;
  final String? email;

  const ProfilePage({
    super.key,
    required this.isGuest,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 30),
            _buildProfileSection(),
            const SizedBox(height: 30),
            _buildSettingsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent, width: 4),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            isGuest ? 'Guest User' : (email?.split('@')[0].toUpperCase() ?? 'User'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isGuest ? 'Browse and save properties' : (email ?? 'user@example.com'),
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          if (isGuest) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text('Register for Full Access', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _activityItem(Icons.favorite_border, 'Favorites', '12'),
              _activityItem(Icons.history, 'Recent', '5'),
              _activityItem(Icons.message_outlined, 'Inquiries', '2'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityItem(IconData icon, String label, String count) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.redAccent),
          const SizedBox(height: 10),
          Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          _settingsItem(Icons.person_outline, 'Personal Information'),
          _settingsItem(Icons.payment_outlined, 'Payment Methods'),
          _settingsItem(Icons.notifications_none, 'Notification Settings'),
          _settingsItem(Icons.security, 'Security & Privacy'),
          const Divider(),
          _settingsItem(
            Icons.logout,
            'Logout',
            color: Colors.red,
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _settingsItem(IconData icon, String title, {Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(color: color ?? Colors.black, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap ?? () {},
    );
  }
}
