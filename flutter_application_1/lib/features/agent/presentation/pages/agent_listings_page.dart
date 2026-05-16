import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/agent_bloc.dart';

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
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                              child: CachedNetworkImage(
                                imageUrl: p.imageUrl,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 110,
                                  height: 110,
                                  color: Colors.grey.shade100,
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 110,
                                  height: 110,
                                  color: Colors.grey.shade100,
                                  child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.title,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: primaryNavy,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p.address,
                                      style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: primaryNavy.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            p.type.name[0].toUpperCase() + p.type.name.substring(1),
                                            style: GoogleFonts.inter(
                                              color: primaryNavy,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '\$${p.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w800,
                                            color: primaryNavy,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Delete button
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
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 20),
                              ),
                            ),
                          ],
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
