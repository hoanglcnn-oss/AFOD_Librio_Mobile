import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  // Viết constructor nhận email và password.
  // Dùng required và super.key? Không!
  // Đây không phải Widget.
  const LoginRequested({required this.email, required this.password});

  // Override props để Equatable so sánh
  // LoginRequested dựa trên email và password.
  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String fullName;
  final String phone;
  final String email;
  final String password;

  const RegisterRequested({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [fullName, phone, email, password];
}

class RestoreSessionRequested extends AuthEvent {
  const RestoreSessionRequested();
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
