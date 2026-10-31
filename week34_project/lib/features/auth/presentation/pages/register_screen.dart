import 'package:flutter/material.dart';

import '../widgets/register_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
                  child: const RegisterForm(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

