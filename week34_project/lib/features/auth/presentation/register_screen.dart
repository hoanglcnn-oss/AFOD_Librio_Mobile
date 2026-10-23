import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản Librobe')),

      // Body có thể cuộn khi bàn phím mở
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Tạo tài khoản Librobe',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Họ và tên'),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Họ và tên không được rỗng';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
                // SỐ ĐIỆN THOẠI — thay đúng validator hiện tại
                validator: (value) {
                  final phone = value?.trim() ?? '';

                  if (phone.isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }

                  // TODO: Cho phép 0 + 9 chữ số
                  // hoặc 84 + 9 chữ số.
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
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Mật khẩu không được rỗng';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Xác nhận mật khẩu không được rỗng';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    print('Form hợp lệ');
                  }
                },
                child: const Text('Đăng ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
