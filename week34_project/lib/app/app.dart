import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/data/fake_auth_repository.dart';
import '../features/auth/presentation/login_screen.dart';

class DofaApp extends StatelessWidget {
  const DofaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider<AuthBloc>(
        // Tạo AuthBloc và truyền FakeAuthRepository.

        create: (context) => AuthBloc(authRepository: FakeAuthRepository()),

        // Đặt LoginScreen làm widget con.
        child: LoginScreen(),
      ),
    );
  }
}
