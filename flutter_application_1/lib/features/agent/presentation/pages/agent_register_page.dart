import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AgentRegisterPage extends StatefulWidget {
  const AgentRegisterPage({super.key});

  @override
  State<AgentRegisterPage> createState() => _AgentRegisterPageState();
}

class _AgentRegisterPageState extends State<AgentRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _suffixController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _agencyController = TextEditingController();
  final _licenseController = TextEditingController();
  final _licenseExpiryController = TextEditingController();
  final _yearsExperienceController = TextEditingController();
  bool _isSubmitting = false;

  static const Color primaryNavy = Color(0xFF0A1D37);
  static const Color gold = Color(0xFFFFD700);

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _suffixController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _agencyController.dispose();
    _licenseController.dispose();
    _licenseExpiryController.dispose();
    _yearsExperienceController.dispose();
    super.dispose();
  }

  /// Pick a date and fill the licenseExpiry field
  Future<void> _pickLicenseExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 20),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryNavy,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _licenseExpiryController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Create user in Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        final firestore = FirebaseFirestore.instance;

        // 2. Create Users document
        // Schema types: userID(PK), lastname(idx), Email(idx), Role(idx), status(idx)
        await firestore.collection('Users').doc(user.uid).set({
          'userID': user.uid,                               // PK
          'Email': _emailController.text.trim(),            // idx
          'Role': 'agent',                                  // idx
          'status': 'pending',                              // idx
          'lastname': _lastNameController.text.trim(),      // idx
          'firstname': _firstNameController.text.trim(),
          'middlename': _middleNameController.text.trim(),
          'suffix': _suffixController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'agencyName': _agencyController.text.trim(),
          'licenseNumber': _licenseController.text.trim(),
          'profileImageUrl': '',
          'dateCreated': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // 3. Create Agent Credentials document (credentialsID = PK, AgentID = FK → Users, licenseNumber = idx, verifiedBy = FK → Users)
        final credentialsRef =
            firestore.collection('Agent Credentials').doc();
        await credentialsRef.set({
          'credentialsID': credentialsRef.id,       // PK
          'AgentID': user.uid,                      // FK → Users
          'agencyName': _agencyController.text.trim(),
          'licenseNumber': _licenseController.text.trim(), // idx
          'licenseExpiry': _licenseExpiryController.text.trim(),
          'yearsExperience': _yearsExperienceController.text.trim(),
          'verificationStatus': 'pending',
          'submittedAt': FieldValue.serverTimestamp(),
          'verifiedAt': null,
          'verifiedBy': '',                         // FK → Users (admin)
        });

        // 4. Store credentialsID back in the Users document (cross-reference)
        await firestore.collection('Users').doc(user.uid).update({
          'credentialsID': credentialsRef.id,
        });

        // Sign out after registration to avoid automatic login conflicts
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const RegistrationPendingPage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agent Registration',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join our network of professional agents. Your application will be reviewed by our admin team.',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // ── Personal Info ───────────────────────────────────────────
              _buildSectionHeader('PERSONAL INFORMATION', Icons.person_rounded),
              const SizedBox(height: 16),

              _buildLabel('FIRST NAME'),
              _buildTextField(
                _firstNameController,
                'John',
                Icons.person_outline,
              ),

              const SizedBox(height: 20),
              _buildLabel('MIDDLE NAME (OPTIONAL)'),
              _buildTextField(
                _middleNameController,
                'Quincy',
                Icons.person_outline,
                isOptional: true,
              ),

              const SizedBox(height: 20),
              _buildLabel('LAST NAME'),
              _buildTextField(
                _lastNameController,
                'Doe',
                Icons.person_outline,
              ),

              const SizedBox(height: 20),
              _buildLabel('SUFFIX (OPTIONAL)'),
              _buildTextField(
                _suffixController,
                'Jr. / III',
                Icons.badge_outlined,
                isOptional: true,
              ),

              const SizedBox(height: 20),
              _buildLabel('PHONE NUMBER'),
              _buildTextField(
                _phoneController,
                '09123456789',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),
              _buildLabel('EMAIL ADDRESS'),
              _buildTextField(
                _emailController,
                'john@agency.com',
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),
              _buildLabel('PASSWORD'),
              _buildTextField(
                _passwordController,
                '********',
                Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 32),

              // ── Professional Credentials ────────────────────────────────
              _buildSectionHeader(
                  'PROFESSIONAL CREDENTIALS', Icons.verified_rounded),
              const SizedBox(height: 16),

              _buildLabel('AGENCY NAME'),
              _buildTextField(
                _agencyController,
                'EstateX Realty',
                Icons.business_outlined,
              ),

              const SizedBox(height: 20),
              _buildLabel('LICENSE NUMBER'),
              _buildTextField(
                _licenseController,
                'RE-123456',
                Icons.badge_outlined,
              ),

              const SizedBox(height: 20),
              _buildLabel('LICENSE EXPIRY DATE'),
              GestureDetector(
                onTap: _pickLicenseExpiry,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _licenseExpiryController,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Field required' : null,
                    decoration: InputDecoration(
                      hintText: 'YYYY-MM-DD',
                      hintStyle:
                          TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(
                        Icons.calendar_today_outlined,
                        color: primaryNavy.withOpacity(0.5),
                      ),
                      suffixIcon: Icon(
                        Icons.arrow_drop_down,
                        color: primaryNavy.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _buildLabel('YEARS OF EXPERIENCE'),
              TextFormField(
                controller: _yearsExperienceController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Field required';
                  final n = int.tryParse(v);
                  if (n == null || n < 0) return 'Enter a valid number';
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'e.g. 5',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(
                    Icons.work_history_outlined,
                    color: primaryNavy.withOpacity(0.5),
                  ),
                  suffixText: 'yrs',
                  suffixStyle: GoogleFonts.inter(
                    color: primaryNavy.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: gold.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: gold, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your application will be reviewed by an admin. Ensure all credentials are accurate before submitting.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Submit Application',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: primaryNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: primaryNavy,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPassword = false,
    bool isOptional = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: (v) {
        if (isOptional) return null;
        return (v == null || v.isEmpty) ? 'Field required' : null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: primaryNavy.withOpacity(0.5)),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

// ── Registration Pending Page ──────────────────────────────────────────────────

class RegistrationPendingPage extends StatelessWidget {
  const RegistrationPendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF0A1D37);
    const Color gold = Color(0xFFFFD700);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.hourglass_empty_rounded, size: 80, color: gold),
              ),
              const SizedBox(height: 32),
              Text(
                'Application Pending',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: primaryNavy,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Thank you for applying! Our administrators are currently reviewing your credentials. You will be notified via email once your account is approved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Back to Login',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
