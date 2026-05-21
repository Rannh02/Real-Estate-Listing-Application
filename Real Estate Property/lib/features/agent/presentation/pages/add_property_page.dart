import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/features/properties/data/models/property.dart';
import '../../bloc/agent_bloc.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/gestures.dart';

class AddPropertyPage extends StatefulWidget {
  final String agentEmail;
  final VoidCallback onSuccess;
  final Property? existingProperty;

  const AddPropertyPage({
    super.key,
    required this.agentEmail,
    required this.onSuccess,
    this.existingProperty,
  });

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl       = TextEditingController();
  final _captionCtrl     = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _priceCtrl       = TextEditingController();
  final _locationCtrl    = TextEditingController();
  final _imageUrlCtrl    = TextEditingController(); // comma-separated URLs
  final _bedsCtrl        = TextEditingController();
  final _bathsCtrl       = TextEditingController();
  final _floorAreaCtrl   = TextEditingController();

  PropertyType   _selectedType   = PropertyType.apartment;
  bool _isSubmitting  = false;
  bool _isGeocoding   = false;
  double? _previewLat;
  double? _previewLng;

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final List<XFile> picked = await _picker.pickMultiImage(
      imageQuality: 70,
    );
    if (picked.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(picked);
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> uploadedUrls = [];
    for (int i = 0; i < _selectedImages.length; i++) {
      final image = _selectedImages[i];
      final safeName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('property_images')
          .child(safeName);
          
      try {
        final bytes = await image.readAsBytes();
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        
        final taskSnapshot = await ref.putData(bytes, metadata);
        if (taskSnapshot.state == TaskState.success) {
          final url = await ref.getDownloadURL();
          uploadedUrls.add(url);
        } else {
          throw Exception('Upload failed with state: ${taskSnapshot.state}');
        }
      } catch (e) {
        if (e.toString().contains('object-not-found')) {
           throw Exception('Firebase Storage is NOT enabled! Please go to your Firebase Console -> Storage -> Click "Get Started" to enable image uploads.');
        }
        rethrow;
      }
    }
    return uploadedUrls;
  }

  static const Color primaryNavy = Color(0xFF0A1D37);
  static const Color gold        = Color(0xFFFFD700);

  Future<void> _geocodeAddress() async {
    final address = _locationCtrl.text.trim();
    if (address.isEmpty) return;
    setState(() => _isGeocoding = true);
    try {
      final locations = await geo.locationFromAddress(address);
      if (locations.isNotEmpty && mounted) {
        setState(() {
          _previewLat = locations.first.latitude;
          _previewLng = locations.first.longitude;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Address not found. Try a more specific address.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }


  static const Map<PropertyType, String> _defaultImages = {
    PropertyType.villa:     'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=800&q=80',
    PropertyType.apartment: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80',
    PropertyType.condo:     'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=800&q=80',
    PropertyType.bungalow:  'https://images.unsplash.com/photo-1568605114967-8130f3a36994?auto=format&fit=crop&w=800&q=80',
    PropertyType.townhouse: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
    PropertyType.house:     'https://images.unsplash.com/photo-1568605114967-8130f3a36994?auto=format&fit=crop&w=800&q=80',
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingProperty != null) {
      final p = widget.existingProperty!;
      _titleCtrl.text = p.title;
      if (p.caption != null) _captionCtrl.text = p.caption!;
      _descCtrl.text = p.description;
      _priceCtrl.text = p.price.toInt().toString();
      _locationCtrl.text = p.address;
      _imageUrlCtrl.text = p.imageUrls.join(', ');
      _bedsCtrl.text = p.bedrooms.toString();
      _bathsCtrl.text = p.bathrooms.toInt().toString();
      _floorAreaCtrl.text = p.floorArea.toInt().toString();
      _selectedType = p.type;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl, _captionCtrl, _descCtrl, _priceCtrl, _locationCtrl,
      _imageUrlCtrl, _bedsCtrl, _bathsCtrl, _floorAreaCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      // 1. Upload new images if any are selected
      List<String> uploadedUrls = [];
      if (_selectedImages.isNotEmpty) {
        uploadedUrls = await _uploadImages();
      }

      // 2. Parse comma-separated existing image URLs if any
      final rawUrls = _imageUrlCtrl.text.trim();
      final existingUrls = rawUrls.isNotEmpty
          ? rawUrls.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : <String>[];

      // 3. Combine both
      final List<String> finalUrls = [...existingUrls, ...uploadedUrls];
      if (finalUrls.isEmpty) {
        finalUrls.add(_defaultImages[_selectedType]!);
      }

    final agentUID = FirebaseAuth.instance.currentUser?.uid ?? widget.agentEmail;

    double? latitude;
    double? longitude;
    final addressText = _locationCtrl.text.trim();

    if (widget.existingProperty != null && widget.existingProperty!.location == addressText) {
      latitude = widget.existingProperty!.latitude;
      longitude = widget.existingProperty!.longitude;
    }

    if ((latitude == null || longitude == null) && addressText.isNotEmpty) {
      try {
        final locations = await geo.locationFromAddress(addressText);
        if (locations.isNotEmpty) {
          latitude = locations.first.latitude;
          longitude = locations.first.longitude;
        }
      } catch (e) {
        debugPrint('Automatic geocoding failed for address: $addressText. Error: $e');
      }
    }

    final property = Property(
      id: widget.existingProperty?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      agentID: widget.existingProperty?.agentID ?? agentUID, // Preserve agentID
      title: _titleCtrl.text.trim(),
      caption: _captionCtrl.text.trim().isEmpty ? null : _captionCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? 'A quality property by EstateX agent.'
          : _descCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim()),
      type: _selectedType,
      status: widget.existingProperty?.status ?? PropertyStatus.pending, // Preserve status if editing
      location: addressText,
      imageUrls: finalUrls,
      bedrooms: int.parse(_bedsCtrl.text.trim()),
      bathrooms: double.parse(_bathsCtrl.text.trim()),
      floorArea: double.parse(_floorAreaCtrl.text.trim()),
      viewCount: widget.existingProperty?.viewCount ?? 0, // Preserve views
      postedBy: widget.existingProperty?.postedBy ?? widget.agentEmail,
      latitude: latitude,
      longitude: longitude,
    );

    if (!mounted) return;
    context.read<AgentBloc>().add(AgentAddProperty(property));

    for (final c in [
      _titleCtrl, _captionCtrl, _descCtrl, _priceCtrl, _locationCtrl,
      _imageUrlCtrl, _bedsCtrl, _bathsCtrl, _floorAreaCtrl,
    ]) {
      c.clear();
    }
    setState(() {
      _selectedType   = PropertyType.apartment;
      _selectedImages.clear();
      _isSubmitting   = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(widget.existingProperty != null ? 'Property updated!' : 'Property listed!',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: primaryNavy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
    widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    }
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
                      Text(widget.existingProperty != null ? 'Edit Listing' : 'Post a Listing',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: primaryNavy)),
                      Text(widget.existingProperty != null ? 'Update your property details' : 'Fill in the details below',
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

                // (Status dropdown removed to force pending approval)


                // ── Title ─────────────────────────────────────────────────
                _label('TITLE'),
                const SizedBox(height: 8),
                _field(_titleCtrl, 'e.g. Modern 3BR Villa',
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 18),

                // ── Caption ───────────────────────────────────────────────
                _label('CAPTION (Optional)'),
                const SizedBox(height: 8),
                _field(_captionCtrl, 'e.g. A beautiful place to live'),
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

                // ── Property Address ──────────────────────────────────────
                _label('PROPERTY ADDRESS'),
                const SizedBox(height: 4),
                Text(
                  'Enter a full address to auto-pin on map (e.g. 123 Ayala Ave, Makati City, Philippines)',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _locationCtrl,
                        textInputAction: TextInputAction.search,
                        onFieldSubmitted: (_) => _geocodeAddress(),
                        decoration: InputDecoration(
                          hintText: 'e.g. 123 Ayala Ave, Makati City, PH',
                          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryNavy, width: 1.5),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isGeocoding ? null : _geocodeAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: _isGeocoding
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.search_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Live map preview ──────────────────────────────────────
                if (_previewLat != null && _previewLng != null) ...[  
                  Container(
                    height: 190,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryNavy.withValues(alpha: 0.18)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(_previewLat!, _previewLng!),
                            zoom: 15.5,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('preview'),
                              position: LatLng(_previewLat!, _previewLng!),
                              infoWindow: InfoWindow(title: _locationCtrl.text.trim()),
                            ),
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                          },
                        ),
                        Positioned(
                          bottom: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: primaryNavy.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_pin, color: Colors.redAccent, size: 14),
                                const SizedBox(width: 4),
                                Text('Pinned', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
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

                // ── Upload Photos ─────────────────────────────────────────
                _label('UPLOAD PHOTOS'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 32, color: primaryNavy),
                        const SizedBox(height: 8),
                        Text('Tap to select images', style: GoogleFonts.inter(color: primaryNavy, fontWeight: FontWeight.w600)),
                        Text('JPEG, PNG format (Max 5MB)', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: kIsWeb
                                      ? NetworkImage(_selectedImages[index].path)
                                      : FileImage(File(_selectedImages[index].path)) as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // ── Image URLs ────────────────────────────────────────────
                _label('OR ENTER IMAGE URLS (optional)'),
                const SizedBox(height: 4),
                Text(
                  'Already hosted somewhere? Multiple URLs separated by commas.',
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
                if (widget.existingProperty != null)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Cancel', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                    ),
                  ),
                if (widget.existingProperty != null)
                  const SizedBox(height: 12),
                  
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
                              Text(widget.existingProperty != null ? 'Update Listing' : 'Publish Listing',
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
