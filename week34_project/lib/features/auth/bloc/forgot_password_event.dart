import 'package:equatable/equatable.dart';

abstract class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => [];
}

class SubmitForgotPassword extends ForgotPasswordEvent {
  final String email;

  const SubmitForgotPassword(this.email);

  @override
  List<Object?> get props => [email];
}
