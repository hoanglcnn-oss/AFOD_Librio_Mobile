import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_state.dart';

class LoadingStatus extends StatelessWidget {
  const LoadingStatus({super.key});

  @override
  Widget build(BuildContext context) {
    // Dùng context.select<AuthBloc, bool>
    // để lấy isLoading từ bloc.state.
    final isLoading = context.select<AuthBloc, bool>(
      (bloc) => bloc.state is AuthLoading,
    );

    if (isLoading) {
      return const Text('Đang xử lý...');
    }

    return const Text('Không xử lý');
  }
}
