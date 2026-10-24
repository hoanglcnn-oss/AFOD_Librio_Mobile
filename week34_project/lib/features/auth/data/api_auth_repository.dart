import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final Dio _dio;

  ApiAuthRepository({Dio? dio}) : _dio = dio ?? DioClient.dio;

  @override
  Future<void> login(String email, String password) async {
    await _dio.post(
      ApiConstants.login,
      data: {'identifier': email, 'password': password},
    );
  }

  @override
  Future<void> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    await _dio.post(
      ApiConstants.register,
      data: {
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'password': password,
      },
    );
  }
}
