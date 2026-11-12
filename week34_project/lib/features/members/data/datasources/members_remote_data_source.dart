import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

abstract class MembersRemoteDataSource {
  Future<Map<String, dynamic>> getMembers({
    required String search,
    int page = 1,
    int limit = 100,
  });

  Future<Map<String, dynamic>> getDebtSummary({
    required String memberId,
    required String token,
  });
}

class MembersRemoteDataSourceImpl implements MembersRemoteDataSource {
  final Dio _dio;

  MembersRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.dio;

  @override
  Future<Map<String, dynamic>> getMembers({
    required String search,
    int page = 1,
    int limit = 100,
  }) async {
    final response = await _dio.get(
      ApiConstants.members,
      queryParameters: {'search': search, 'page': page, 'limit': limit},
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getDebtSummary({
    required String memberId,
    required String token,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.members}/$memberId/debt-summary',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }
}
