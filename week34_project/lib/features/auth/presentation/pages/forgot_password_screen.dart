import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:week34_project/features/auth/bloc/forgot_password_bloc.dart';
import 'package:week34_project/features/auth/bloc/forgot_password_event.dart';
import 'package:week34_project/features/auth/bloc/forgot_password_state.dart';
import 'package:week34_project/features/auth/data/api_auth_repository.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgotPasswordBloc(authRepository: ApiAuthRepository()),
      child: const _ForgotPasswordForm(),
    );
  }
}

class _ForgotPasswordForm extends StatefulWidget {
  const _ForgotPasswordForm();

  @override
  State<_ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<_ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Vui lòng nhập email';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(email)) {
      return 'Email không đúng định dạng';
    }

    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<ForgotPasswordBloc>().add(
      SubmitForgotPassword(_emailController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
        listener: (context, state) {
          if (state is ForgotPasswordFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isLoading = state is ForgotPasswordLoading;
          final isSuccess = state is ForgotPasswordSuccess;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.mark_email_read_outlined, size: 64),
                        const SizedBox(height: 20),

                        Text(
                          'Quên mật khẩu?',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),

                        const Text(
                          'Nhập email đã đăng ký. Nếu tài khoản tồn tại, '
                          'chúng tôi sẽ gửi hướng dẫn đặt lại mật khẩu.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        TextFormField(
                          controller: _emailController,
                          enabled: !isLoading && !isSuccess,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'name@example.com',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateEmail,
                          onFieldSubmitted: (_) {
                            if (!isLoading && !isSuccess) {
                              _submit();
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        if (isSuccess) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.message,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Hãy kiểm tra cả thư rác (Spam).',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Gửi hướng dẫn đặt lại mật khẩu',
                                    ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        TextButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Quay lại đăng nhập'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
