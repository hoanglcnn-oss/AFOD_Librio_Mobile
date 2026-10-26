import 'package:dio/dio.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'auth_repository.dart';
import 'models/auth_response.dart';

class ApiAuthRepository implements AuthRepository {
  final Dio _dio;

  ApiAuthRepository({Dio? dio}) : _dio = dio ?? DioClient.dio;

  @override
  Future<AuthResponse> login(String email, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'identifier': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AuthResponse> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'password': password,
      },
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UserProfile> getCurrentUser(String token) async {
    final response = await _dio.get(
      ApiConstants.me,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }
}
