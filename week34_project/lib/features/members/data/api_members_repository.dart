import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/dio_client.dart';
import 'members_repository.dart';
import 'models/member.dart';

class ApiMembersRepository implements MembersRepository {
  final Dio _dio;

  ApiMembersRepository({Dio? dio}) : _dio = dio ?? DioClient.dio;

  @override
  Future<Member?> findByEmail(String email) async {
    final normalized = email.trim().toLowerCase();

    if (normalized.isEmpty) {
      return null;
    }

    var page = 1;

    while (true) {
      final response = await _dio.get(
        '/members',
        queryParameters: {'search': normalized, 'page': page, 'limit': 100},
      );

      final json = response.data as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>;
      final meta = json['meta'] as Map<String, dynamic>;
      debugPrint('MEMBERS API: status=${response.statusCode}');
      debugPrint('MEMBERS API: data.length=${data.length}');
      debugPrint('MEMBERS API: hasNext=${meta['hasNextPage']}');
      final matches = data
          .map((item) => Member.fromJson(item as Map<String, dynamic>))
          .where((member) => member.email.trim().toLowerCase() == normalized)
          .toList();

      if (matches.length == 1) {
        return matches.single;
      }

      if (matches.length > 1) {
        throw StateError('Nhiều hồ sơ có cùng email');
      }

      if (meta['hasNextPage'] != true) {
        return null;
      }

      page++;
    }
  }
}
