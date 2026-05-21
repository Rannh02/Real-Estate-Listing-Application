part of 'login_bloc.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class LoginEmailChanged extends LoginEvent {
  const LoginEmailChanged(this.email);
  final String email;

  @override
  List<Object> get props => [email];
}

class LoginPasswordChanged extends LoginEvent {
  const LoginPasswordChanged(this.password);
  final String password;

  @override
  List<Object> get props => [password];
}

class LoginSubmitted extends LoginEvent {}

class GuestLoginPressed extends LoginEvent {}

class ForgotPasswordPressed extends LoginEvent {}

class RegisterPressed extends LoginEvent {}

class GoogleLoginPressed extends LoginEvent {}
