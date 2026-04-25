import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
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
      
      // Simulating network delay
      await Future.delayed(const Duration(seconds: 2));
      
      if (state.email == "test@example.com" && state.password == "password") {
        emit(state.copyWith(status: LoginStatus.success));
      } else {
        emit(state.copyWith(status: LoginStatus.failure, errorMessage: "Invalid credentials"));
      }
    });

    on<GuestLoginPressed>((event, emit) {
      emit(state.copyWith(status: LoginStatus.guestSuccess));
    });

    on<ForgotPasswordPressed>((event, emit) {
      // Handle forgot password navigation or logic
    });

    on<RegisterPressed>((event, emit) {
      // Handle registration navigation or logic
    });
  }
}
