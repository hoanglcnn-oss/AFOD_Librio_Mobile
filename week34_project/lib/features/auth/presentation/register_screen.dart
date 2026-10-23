import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar với tiêu đề Đăng ký
      appBar: AppBar(title: const Text('Tạo tài khoản Librobe')),

      // Body có thể cuộn khi bàn phím mở
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        // Column chứa tiêu đề và các input
        child: Column(
          children: [
            Text(
              'Tạo tài khoản Librobe',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            TextFormField(decoration: InputDecoration(labelText: 'Họ và tên')),
            const SizedBox(height: 20),
            TextFormField(
              decoration: InputDecoration(labelText: 'Số điện thoại'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Mật khẩu'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Xác nhận mật khẩu'),
            ),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: () {}, child: Text('Đăng ký')),
          ],
        ),
      ),
    );
  }
}
