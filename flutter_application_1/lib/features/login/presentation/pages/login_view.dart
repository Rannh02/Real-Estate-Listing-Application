import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/login_bloc.dart';
import '../../../properties/presentation/pages/main_page.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
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
        } else if (state.status == LoginStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Authentication failed')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 80),
                const Icon(
                  Icons.lock_person_outlined,
                  size: 100,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 40),
                const Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter your credentials to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 50),
                
                // Email Field
                TextField(
                  onChanged: (email) => context.read<LoginBloc>().add(LoginEmailChanged(email)),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email, color: Colors.redAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Password Field
                TextField(
                  obscureText: true,
                  onChanged: (password) => context.read<LoginBloc>().add(LoginPasswordChanged(password)),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock, color: Colors.redAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.read<LoginBloc>().add(ForgotPasswordPressed()),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Login Button
                BlocBuilder<LoginBloc, LoginState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.status == LoginStatus.loading
                          ? null
                          : () => context.read<LoginBloc>().add(LoginSubmitted()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: state.status == LoginStatus.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Guest Login Button
                OutlinedButton(
                  onPressed: () => context.read<LoginBloc>().add(GuestLoginPressed()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('Login as Guest', style: TextStyle(fontSize: 18)),
                ),
                
                const SizedBox(height: 40),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () => context.read<LoginBloc>().add(RegisterPressed()),
                      child: const Text(
                        'Register',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
