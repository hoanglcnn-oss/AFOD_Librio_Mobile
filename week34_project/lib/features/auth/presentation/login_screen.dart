import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_event.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DOFA Login')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // Hiện SnackBar với nội dung state.message.
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const CircularProgressIndicator();
                  }

                  if (state is AuthFailure) {
                    return Text(state.message);
                  }

                  if (state is AuthSuccess) {
                    return Text(state.message);
                  }

                  return const Text('Sẵn sàng đăng nhập');
                },
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  context.read<AuthBloc>().add(
                    const LoginRequested(
                      email: 'test@example.com',
                      password: '123456',
                    ),
                  );
                },
                child: const Text('Login Test'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
