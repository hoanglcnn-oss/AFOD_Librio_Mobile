import 'package:flutter/material.dart';

import '../widgets/login_form.dart';

export '../widgets/loading_status.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập Librobe')),
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
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: const LoginForm(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
