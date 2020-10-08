part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent {}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  SignInEvent(this.email, this.password);
}

class SignOutEvent extends AuthEvent {}

class CheckIfSignedInEvent extends AuthEvent {}

class LoadUserEvent extends AuthEvent {
  final CurrentUser user;
  final bool forceNetwork;
  LoadUserEvent(this.user, this.forceNetwork);
}

class RegisterUserEvent extends AuthEvent {
  final CurrentUser user;
  final String password;
  final DateTime dob;
  RegisterUserEvent(this.user, this.password, this.dob);
}

class ForgetPasswordEvent extends AuthEvent {
  final String email;

  ForgetPasswordEvent(this.email);
}
