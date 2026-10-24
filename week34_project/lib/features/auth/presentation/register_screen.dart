import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
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
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                          ),
                          keyboardType: TextInputType.phone,
                          // SỐ ĐIỆN THOẠI — thay đúng validator hiện tại
                          validator: (value) {
                            final phone = value?.trim() ?? '';

                            if (phone.isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }

                            // Cho phép 0 + 9 chữ số hoặc 84 + 9 chữ số.
                            final phoneRegex = RegExp(r'^(0|84)\d{9}$');

                            if (!phoneRegex.hasMatch(phone)) {
                              return 'SĐT phải có 10 chữ số bắt đầu bằng 0 hoặc 11 chữ số bắt đầu bằng 84';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
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

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                debugPrint('Form hợp lệ - chưa gọi API');
                              }
                            },
                            child: const Text('Đăng ký'),
                          ),
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
