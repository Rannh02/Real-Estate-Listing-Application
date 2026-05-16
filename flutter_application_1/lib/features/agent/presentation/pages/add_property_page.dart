import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/features/properties/data/models/property.dart';
import '../../bloc/agent_bloc.dart';

class AddPropertyPage extends StatefulWidget {
  final String agentEmail;
  final VoidCallback onSuccess;

  const AddPropertyPage({
    super.key,
    required this.agentEmail,
    required this.onSuccess,
  });

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl       = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _priceCtrl       = TextEditingController();
  final _locationCtrl    = TextEditingController();
  final _imageUrlCtrl    = TextEditingController(); // comma-separated URLs
  final _bedsCtrl        = TextEditingController();
  final _bathsCtrl       = TextEditingController();
  final _floorAreaCtrl   = TextEditingController();

  PropertyType   _selectedType   = PropertyType.apartment;
  PropertyStatus _selectedStatus = PropertyStatus.available;
  bool _isSubmitting = false;

  static const Color primaryNavy = Color(0xFF0A1D37);
  static const Color gold        = Color(0xFFFFD700);

  static const Map<PropertyType, String> _defaultImages = {
    PropertyType.villa:     'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=800&q=80',
    PropertyType.apartment: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80',
    PropertyType.condo:     'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=800&q=80',
    PropertyType.bungalow:  'https://images.unsplash.com/photo-1568605114967-8130f3a36994?auto=format&fit=crop&w=800&q=80',
    PropertyType.townhouse: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
    PropertyType.house:     'https://images.unsplash.com/photo-1568605114967-8130f3a36994?auto=format&fit=crop&w=800&q=80',
  };

  @override
  void dispose() {
    for (final c in [
      _titleCtrl, _descCtrl, _priceCtrl, _locationCtrl,
      _imageUrlCtrl, _bedsCtrl, _bathsCtrl, _floorAreaCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    // Parse comma-separated image URLs or fall back to default
    final rawUrls = _imageUrlCtrl.text.trim();
    final imageUrls = rawUrls.isNotEmpty
        ? rawUrls.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : [_defaultImages[_selectedType]!];

    final agentUID = FirebaseAuth.instance.currentUser?.uid ?? widget.agentEmail;

    final property = Property(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      agentID: agentUID,                        // FK → Users (idx)
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? 'A quality property by EstateX agent.'
          : _descCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim()),    // idx
      type: _selectedType,                             // idx — propertyType
      status: _selectedStatus,                         // idx
      location: _locationCtrl.text.trim(),
      imageUrls: imageUrls,
      bedrooms: int.parse(_bedsCtrl.text.trim()),
      bathrooms: double.parse(_bathsCtrl.text.trim()), // idx
      floorArea: double.parse(_floorAreaCtrl.text.trim()),
      viewCount: 0,
      postedBy: widget.agentEmail,
    );

    context.read<AgentBloc>().add(AgentAddProperty(property));

    for (final c in [
      _titleCtrl, _descCtrl, _priceCtrl, _locationCtrl,
      _imageUrlCtrl, _bedsCtrl, _bathsCtrl, _floorAreaCtrl,
    ]) {
      c.clear();
    }
    setState(() {
      _selectedType   = PropertyType.apartment;
      _selectedStatus = PropertyStatus.available;
      _isSubmitting   = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Property listed!',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: primaryNavy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryNavy,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_home_work,
                        color: gold, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Post a Listing',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: primaryNavy)),
                      Text('Fill in the details below',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ]),
                const SizedBox(height: 28),

                // ── Property Type (idx) ───────────────────────────────────
                _label('PROPERTY TYPE (idx)'),
                const SizedBox(height: 8),
                _dropdown<PropertyType>(
                  value: _selectedType,
                  items: PropertyType.values,
                  labelOf: (t) =>
                      t.name[0].toUpperCase() + t.name.substring(1),
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
                const SizedBox(height: 18),

                // ── Status (idx) ──────────────────────────────────────────
                _label('STATUS (idx)'),
                const SizedBox(height: 8),
                _dropdown<PropertyStatus>(
                  value: _selectedStatus,
                  items: PropertyStatus.values,
                  labelOf: (s) => s.display,
                  onChanged: (v) => setState(() => _selectedStatus = v!),
                ),
                const SizedBox(height: 18),

                // ── Title ─────────────────────────────────────────────────
                _label('TITLE'),
                const SizedBox(height: 8),
                _field(_titleCtrl, 'e.g. Modern 3BR Villa',
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 18),

                // ── Price (idx) ───────────────────────────────────────────
                _label('PRICE ₱ (idx)'),
                const SizedBox(height: 8),
                _field(_priceCtrl, 'e.g. 4500000',
                    type: TextInputType.number, validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                }),
                const SizedBox(height: 18),

                // ── Location ──────────────────────────────────────────────
                _label('LOCATION'),
                const SizedBox(height: 8),
                _field(_locationCtrl, 'e.g. 123 Main St, City',
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 18),

                // ── Beds / Baths (idx) / Floor Area ───────────────────────
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('BEDS'),
                      const SizedBox(height: 8),
                      _field(_bedsCtrl, '3',
                          type: TextInputType.number, validator: (v) {
                        if (v == null || v.isEmpty) return 'Req';
                        if (int.tryParse(v) == null) return 'Int';
                        return null;
                      }),
                    ],
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('BATHS (idx)'),
                      const SizedBox(height: 8),
                      _field(_bathsCtrl, '2',
                          type: TextInputType.number, validator: (v) {
                        if (v == null || v.isEmpty) return 'Req';
                        if (double.tryParse(v) == null) return 'Num';
                        return null;
                      }),
                    ],
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('FLOOR AREA m²'),
                      const SizedBox(height: 8),
                      _field(_floorAreaCtrl, '120',
                          type: TextInputType.number, validator: (v) {
                        if (v == null || v.isEmpty) return 'Req';
                        if (double.tryParse(v) == null) return 'Num';
                        return null;
                      }),
                    ],
                  )),
                ]),
                const SizedBox(height: 18),

                // ── Image URLs ────────────────────────────────────────────
                _label('IMAGE URLS (optional — comma-separated)'),
                const SizedBox(height: 4),
                Text(
                  'Leave blank for a default image. Multiple URLs separated by commas.',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                _field(_imageUrlCtrl, 'https://..., https://...'),
                const SizedBox(height: 18),

                // ── Description ───────────────────────────────────────────
                _label('DESCRIPTION (optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: primaryNavy),
                  decoration: _inputDeco('Describe the property...'),
                ),
                const SizedBox(height: 32),

                // ── Submit ────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.publish_rounded, size: 20),
                              const SizedBox(width: 10),
                              Text('Publish Listing',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
        t,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: primaryNavy,
          letterSpacing: 1.1,
        ),
      );

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: GoogleFonts.inter(
              color: primaryNavy,
              fontSize: 14,
              fontWeight: FontWeight.w600),
          onChanged: onChanged,
          items: items
              .map((t) => DropdownMenuItem<T>(
                    value: t,
                    child: Text(labelOf(t)),
                  ))
              .toList(),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide:
                BorderSide(color: Color(0xFF0A1D37), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade300)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: primaryNavy),
      decoration: _inputDeco(hint),
    );
  }
}
