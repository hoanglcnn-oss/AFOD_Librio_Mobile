import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

abstract class BorrowingsRemoteDataSource {
  Future<Map<String, dynamic>> createBorrowing({
    required Map<String, dynamic> data,
    required String token,
  });
}

class BorrowingsRemoteDataSourceImpl implements BorrowingsRemoteDataSource {
  final Dio _dio;

  BorrowingsRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.dio;

  @override
  Future<Map<String, dynamic>> createBorrowing({
    required Map<String, dynamic> data,
    required String token,
  }) async {
    final response = await _dio.post(
      ApiConstants.borrowings,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }
}

