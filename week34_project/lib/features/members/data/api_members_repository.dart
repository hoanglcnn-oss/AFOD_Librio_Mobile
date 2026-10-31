import 'package:dio/dio.dart';

import 'datasources/members_remote_data_source.dart';
import 'members_repository.dart';
import 'models/member.dart';

class ApiMembersRepository implements MembersRepository {
  final MembersRemoteDataSource _remoteDataSource;

  ApiMembersRepository({MembersRemoteDataSource? remoteDataSource, Dio? dio})
    : _remoteDataSource =
          remoteDataSource ?? MembersRemoteDataSourceImpl(dio: dio);

  @override
  Future<Member?> findByEmail(String email) async {
    final normalized = email.trim().toLowerCase();

    if (normalized.isEmpty) {
      return null;
    }

    var page = 1;

    while (true) {
      final json = await _remoteDataSource.getMembers(
        search: normalized,
        page: page,
        limit: 100,
      );

      final data = json['data'] as List<dynamic>;
      final meta = json['meta'] as Map<String, dynamic>;

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
