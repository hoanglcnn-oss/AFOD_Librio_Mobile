import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/storage/token_storage.dart';
import '../core/widgets/app_scroll_behaviour.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_event.dart';
import '../features/auth/data/repositories/api_auth_repository.dart';
import 'router/app_router.dart';

class DofaApp extends StatefulWidget {
  final AuthBloc? authBloc;

  const DofaApp({super.key, this.authBloc});

  @override
  State<DofaApp> createState() => _DofaAppState();
}

class _DofaAppState extends State<DofaApp> {
  late final AuthBloc _authBloc;
  late final bool _isCustomAuthBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _isCustomAuthBloc = widget.authBloc != null;
    _authBloc = widget.authBloc ??
        (AuthBloc(
          authRepository: ApiAuthRepository(),
          tokenStorage: TokenStorage(),
        )..add(const RestoreSessionRequested()));
    _router = createAppRouter(_authBloc);
  }

  @override
  void dispose() {
    _router.dispose();
    if (!_isCustomAuthBloc) {
      _authBloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: MaterialApp.router(
        routerConfig: _router,
        scrollBehavior: const AppScrollBehavior(),
        debugShowCheckedModeBanner: false,
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
      ),
    );
  }
}
