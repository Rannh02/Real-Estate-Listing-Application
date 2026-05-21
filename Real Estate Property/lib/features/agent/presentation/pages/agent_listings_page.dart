import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../properties/data/models/property.dart';
import '../../bloc/agent_bloc.dart';
import 'add_property_page.dart' as flutter_application_1_add;
import '../../../properties/presentation/pages/property_details_page.dart' as flutter_application_1_details;
import '../../../properties/bloc/properties_bloc.dart';
import '../../../properties/presentation/pages/notifications_page.dart';

class AgentListingsPage extends StatelessWidget {
  final String agentEmail;
  final VoidCallback onAddTap;

  const AgentListingsPage({
    super.key,
    required this.agentEmail,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF0A1D37);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: const BoxDecoration(
                color: primaryNavy,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.home_work, color: Color(0xFFFFD700), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '8990 EstateX',
                            style: GoogleFonts.montserrat(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Notifications')
                            .where('recipientID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                            .where('isRead', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                                  );
                                },
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    child: Center(
                                      child: Text(
                                        '$unreadCount',
                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'My Listings',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  BlocBuilder<AgentBloc, AgentState>(
                    builder: (context, state) => Text(
                      '${state.listings.length} propert${state.listings.length == 1 ? 'y' : 'ies'} posted',
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: BlocBuilder<AgentBloc, AgentState>(
                builder: (context, state) {
                  if (state.status == AgentStatus.loading) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryNavy),
                    );
                  }

                  if (state.listings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: primaryNavy.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_home_work_outlined, size: 48, color: primaryNavy),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No listings yet',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to post your first property',
                            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: onAddTap,
                            icon: const Icon(Icons.add),
                            label: Text('Post a Property', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: state.listings.length,
                    itemBuilder: (context, index) {
                      final p = state.listings[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (context) => PropertiesBloc()..add(PropertiesFetchStarted()),
                                child: flutter_application_1_details.PropertyDetailsPage(
                                  property: p,
                                  isGuest: false,
                                  isAgentMode: true,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header (Title + Delete button)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: primaryNavy.withOpacity(0.1),
                                          radius: 16,
                                          child: const Icon(Icons.person, color: primaryNavy, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            p.title,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: primaryNavy,
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
                                      GestureDetector(
                                        onTap: () {
                                          final agentBloc = context.read<AgentBloc>();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => BlocProvider.value(
                                                value: agentBloc,
                                                child: flutter_application_1_add.AddPropertyPage(
                                                  agentEmail: agentEmail,
                                                  existingProperty: p,
                                                  onSuccess: onAddTap,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Icon(Icons.edit_outlined, color: primaryNavy, size: 22),
                                      ),
                                      const SizedBox(width: 16),
                                      GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          title: Text('Delete Listing', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primaryNavy)),
                                          content: Text('Remove "${p.title}" from your listings?', style: GoogleFonts.inter()),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                context.read<AgentBloc>().add(AgentDeleteProperty(p.id));
                                                Navigator.pop(context);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red.shade600,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 22),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                            
                            // Image (Full width, Instagram style)
                            CachedNetworkImage(
                              imageUrl: p.imageUrl,
                              width: double.infinity,
                              height: MediaQuery.of(context).size.width - 40, // Square aspect ratio
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: double.infinity,
                                height: MediaQuery.of(context).size.width - 40,
                                color: Colors.grey.shade100,
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                width: double.infinity,
                                height: MediaQuery.of(context).size.width - 40,
                                color: Colors.grey.shade100,
                                child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40),
                              ),
                            ),

                            // Footer (Price, Address, Type, Status)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '\$${p.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800,
                                          color: primaryNavy,
                                          fontSize: 18,
                                        ),
                                      ),
                                       Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                         decoration: BoxDecoration(
                                           color: p.status == PropertyStatus.sold
                                               ? Colors.grey.shade300
                                               : p.status.name == 'pending'
                                                   ? Colors.orange.shade50
                                                   : Colors.green.shade50,
                                           borderRadius: BorderRadius.circular(8),
                                           border: Border.all(
                                               color: p.status == PropertyStatus.sold
                                                   ? Colors.grey.shade500
                                                   : p.status.name == 'pending'
                                                       ? Colors.orange.shade200
                                                       : Colors.green.shade200),
                                         ),
                                         child: Text(
                                           p.status.display.toUpperCase(),
                                           style: GoogleFonts.inter(
                                             fontSize: 10,
                                             fontWeight: FontWeight.w800,
                                             color: p.status == PropertyStatus.sold
                                                 ? Colors.grey.shade700
                                                 : p.status.name == 'pending'
                                                     ? Colors.orange.shade700
                                                     : Colors.green.shade700,
                                           ),
                                         ),
                                       ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          p.address,
                                          style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryNavy.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      p.type.name[0].toUpperCase() + p.type.name.substring(1),
                                      style: GoogleFonts.inter(
                                        color: primaryNavy,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
