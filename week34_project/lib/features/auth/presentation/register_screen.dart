import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body có thể cuộn khi bàn phím mở
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = MediaQuery.sizeOf(context).width >= 600;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: isTablet
                    ? (constraints.maxHeight - 32).clamp(0.0, double.infinity)
                    : 0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: isTablet
                      ? const BoxConstraints(maxWidth: 600)
                      : const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          'Đăng Ký',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),

                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Họ và tên',
                          ),

                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Họ và tên không được rỗng';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                          ),
                          keyboardType: TextInputType.phone,

                          validator: (value) {
                            final phone = value?.trim() ?? '';

                            if (phone.isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }

                            final phoneRegex = RegExp(r'^0[35789]\d{8}$');

                            if (!phoneRegex.hasMatch(phone)) {
                              return 'SĐT phải có 10 chữ số với đầu số 03, 05, 07, 08 hoặc 09';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            // Chuẩn hóa chuỗi bằng trim().
                            final email = value?.trim() ?? '';

                            // Kiểm tra email rỗng.
                            if (email.isEmpty) {
                              return 'Vui lòng nhập email';
                            }

                            // Kiểm tra Regex với biến email đã chuẩn hóa.
                            final emailRegex = RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                            );

                            if (!emailRegex.hasMatch(email)) {
                              return 'Email không hợp lệ';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Hiện mật khẩu'
                                  : 'Ẩn mật khẩu',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }

                            if (value.length < 8) {
                              return 'Mật khẩu phải có ít nhất 8 ký tự';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Xác nhận mật khẩu',
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirmPassword
                                  ? 'Hiện mật khẩu'
                                  : 'Ẩn mật khẩu',
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Xác nhận mật khẩu không được rỗng';
                            }
                            if (value != _passwordController.text) {
                              return 'Mật khẩu xác nhận không khớp';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        BlocConsumer<AuthBloc, AuthState>(
                          listener: (context, state) {
                            if (state is AuthSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(state.message)),
                              );

                              Navigator.pop(context);
                            }

                            if (state is AuthFailure) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(state.message)),
                              );
                            }
                          },
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;

                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        if (_formKey.currentState!.validate()) {
                                          context.read<AuthBloc>().add(
                                            RegisterRequested(
                                              fullName: _fullNameController.text
                                                  .trim(),
                                              phone: _phoneController.text
                                                  .trim(),
                                              email: _emailController.text
                                                  .trim(),
                                              password:
                                                  _passwordController.text,
                                            ),
                                          );
                                        }
                                      },
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Đăng ký'),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Đã có tài khoản?'),

                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Đăng nhập'),
                            ),
                          ],
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
