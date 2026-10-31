import 'package:dio/dio.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';

import 'datasources/auth_remote_data_source.dart';
import 'auth_repository.dart';
import 'models/auth_response.dart';

class ApiAuthRepository implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  ApiAuthRepository({AuthRemoteDataSource? remoteDataSource, Dio? dio})
    : _remoteDataSource =
          remoteDataSource ?? AuthRemoteDataSourceImpl(dio: dio);

  @override
  Future<AuthResponse> login(String email, String password) async {
    final data = await _remoteDataSource.login(
      identifier: email,
      password: password,
    );

    return AuthResponse.fromJson(data);
  }

  @override
  Future<AuthResponse> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final data = await _remoteDataSource.register(
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
    );

    return AuthResponse.fromJson(data);
  }

  @override
  Future<UserProfile> getCurrentUser(String token) async {
    final data = await _remoteDataSource.getCurrentUser(token);

    return UserProfile.fromJson(data);
  }
}
