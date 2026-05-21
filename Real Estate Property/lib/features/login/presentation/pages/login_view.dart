import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/login_bloc.dart';
import '../../../properties/presentation/pages/main_page.dart';
import '../../../agent/presentation/pages/agent_main_page.dart';
import '../../../agent/presentation/pages/agent_register_page.dart';
import '../../../agent/presentation/pages/admin_dashboard_page.dart';
import 'register_page.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryNavy = const Color(0xFF0A1D37);
    final Color inputBg = const Color(0xFFF1F5F9);

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state.status == LoginStatus.success || state.status == LoginStatus.guestSuccess) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MainPage(
                isGuest: state.status == LoginStatus.guestSuccess,
                email: state.status == LoginStatus.success ? state.email : null,
              ),
            ),
          );
        } else if (state.status == LoginStatus.agentSuccess) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AgentMainPage(email: state.email),
            ),
          );
        } else if (state.status == LoginStatus.adminSuccess) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const AdminDashboardPage(),
            ),
          );
        } else if (state.status == LoginStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Authentication failed')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Curved Header Section
              ClipPath(
                clipper: HeaderClipper(),
                child: Container(
                  height: 320,
                  width: double.infinity,
                  color: primaryNavy,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Container
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24, width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.home_filled,
                              color: Color(0xFFFFD700), // Gold
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '8990 EstateX',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'FIND. BUY. LIVE.',
                          style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to your account',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email Field
                    Text(
                      'EMAIL ADDRESS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: primaryNavy,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (email) =>
                          context.read<LoginBloc>().add(LoginEmailChanged(email)),
                      decoration: InputDecoration(
                        hintText: 'john@example.com',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFFEEF2FF), // Very light blue
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryNavy),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade100),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryNavy, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Password Field
                    Text(
                      'PASSWORD',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: primaryNavy,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      obscureText: true,
                      onChanged: (password) =>
                          context.read<LoginBloc>().add(LoginPasswordChanged(password)),
                      decoration: InputDecoration(
                        hintText: '********',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryNavy, width: 1),
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            context.read<LoginBloc>().add(ForgotPasswordPressed()),
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.inter(
                            color: primaryNavy,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      child: BlocBuilder<LoginBloc, LoginState>(
                        builder: (context, state) {
                          return ElevatedButton(
                            onPressed: state.status == LoginStatus.loading
                                ? null
                                : () => context.read<LoginBloc>().add(LoginSubmitted()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: state.status == LoginStatus.loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Sign In',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Guest Login Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            context.read<LoginBloc>().add(GuestLoginPressed()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryNavy,
                          side: BorderSide(color: primaryNavy, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Continue as Guest',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.read<LoginBloc>().add(GoogleLoginPressed()),
                        icon: const Icon(Icons.account_circle, size: 24, color: Colors.red), // Reliable icon
                        label: Text(
                          'Sign in with Google',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterPage()),
                            );
                          },
                          child: Text(
                            'Register',
                            style: GoogleFonts.inter(
                              color: primaryNavy,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 0),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Are you an agent?",
                            style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AgentRegisterPage()),
                              );
                            },
                            child: Text(
                              'Apply Here',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFB8860B), // Dark Gold
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

