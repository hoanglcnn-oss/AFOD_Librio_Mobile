import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/data/fake_auth_repository.dart';
import '../features/auth/presentation/login_screen.dart';

class DofaApp extends StatelessWidget {
  const DofaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // builder: (context, child) {
      //   return MediaQuery(
      //     data: MediaQuery.of(context)
      //         .copyWith(textScaler: const TextScaler.linear(1.5)),
      //     child: child ?? const SizedBox.shrink(),
      //   );
      // },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: GoogleFonts.manropeTextTheme(),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF0D9488),
            minimumSize: const Size(48, 48),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 2),
          ),
          errorStyle: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 12),
        ),
      ),
      home: BlocProvider<AuthBloc>(
        // Tạo AuthBloc và truyền FakeAuthRepository.

        create: (context) => AuthBloc(authRepository: FakeAuthRepository()),

        // Đặt LoginScreen làm widget con.
        child: const LoginScreen(),
      ),
    );
  }
}
