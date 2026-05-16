import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../agent/data/repositories/agent_auth_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LoginBloc() : super(const LoginState()) {
    on<LoginEmailChanged>((event, emit) {
      emit(state.copyWith(email: event.email, status: LoginStatus.initial));
    });

    on<LoginPasswordChanged>((event, emit) {
      emit(state.copyWith(password: event.password, status: LoginStatus.initial));
    });

    on<LoginSubmitted>((event, emit) async {
      if (state.email.isEmpty || state.password.isEmpty) {
        emit(state.copyWith(status: LoginStatus.failure, errorMessage: "Please fill all fields"));
        return;
      }
      
      emit(state.copyWith(status: LoginStatus.loading));
      
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: state.email.trim(),
          password: state.password.trim(),
        );

        await _handleUserRole(userCredential.user, emit);
      } on FirebaseAuthException catch (e) {
        emit(state.copyWith(status: LoginStatus.failure, errorMessage: e.message ?? "Authentication failed"));
      } catch (e) {
        emit(state.copyWith(status: LoginStatus.failure, errorMessage: "An error occurred: $e"));
      }
    });

    on<GoogleLoginPressed>((event, emit) async {
      emit(state.copyWith(status: LoginStatus.loading));
      try {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          emit(state.copyWith(status: LoginStatus.initial));
          return;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        
        // Gmail login always sets/checks for 'buyer' role if new
        await _handleUserRole(userCredential.user, emit, isGoogle: true);
      } catch (e) {
        emit(state.copyWith(status: LoginStatus.failure, errorMessage: "Google Sign-In failed: $e"));
      }
    });

    on<GuestLoginPressed>((event, emit) {
      emit(state.copyWith(status: LoginStatus.guestSuccess));
    });

    on<ForgotPasswordPressed>((event, emit) {
      // Handle forgot password
    });

    on<RegisterPressed>((event, emit) {
      // Handle registration
    });
  }

  Future<void> _handleUserRole(User? user, Emitter<LoginState> emit, {bool isGoogle = false}) async {
    if (user == null) return;

    final userDoc = await _firestore.collection('Users').doc(user.uid).get();

    if (!userDoc.exists) {
      // If user doesn't exist in Firestore, create them as a 'buyer'
      final newUser = {
        'userID': user.uid,
        'Email': user.email,
        'Role': 'buyer',
        'status': 'active',
        'firstname': user.displayName?.split(' ').first ?? '',
        'lastname': user.displayName?.split(' ').last ?? '',
        'middlename': '',
        'phoneNumber': user.phoneNumber ?? '',
        'profileImageUrl': user.photoURL ?? '',
        'suffix': '',
        'dateCreated': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('Users').doc(user.uid).set(newUser);
      emit(state.copyWith(status: LoginStatus.success, email: user.email));
    } else {
      // User exists, check their role and status
      final data = userDoc.data()!;
      final role = data['Role'] ?? 'buyer';
      final status = data['status'] ?? 'active';

      if (status == 'blocked') {
        emit(state.copyWith(status: LoginStatus.failure, errorMessage: "Your account has been blocked."));
        return;
      }

      if (status == 'pending') {
        emit(state.copyWith(status: LoginStatus.failure, errorMessage: "Your application is still pending admin approval."));
        return;
      }

      if (role == 'admin') {
        emit(state.copyWith(status: LoginStatus.adminSuccess, email: user.email));
      } else if (role == 'agent') {
        emit(state.copyWith(status: LoginStatus.agentSuccess, email: user.email));
      } else {
        emit(state.copyWith(status: LoginStatus.success, email: user.email));
      }
    }
  }
}
