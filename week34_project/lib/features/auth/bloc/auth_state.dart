import 'package:equatable/equatable.dart';

import '../data/models/user_profile.dart';

// Tạo abstract class AuthState kế thừa Equatable, constructor const
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserProfile user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthRegisterSuccess extends AuthState {
  const AuthRegisterSuccess();
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthSessionFailure extends AuthState {
  final String message;

  const AuthSessionFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
