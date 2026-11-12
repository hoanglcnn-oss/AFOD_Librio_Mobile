import 'package:dio/dio.dart';

import '../../../../core/storage/token_storage.dart';
import 'datasources/members_remote_data_source.dart';
import 'members_repository.dart';
import 'models/member.dart';
import 'models/member_debt_summary.dart';

class ApiMembersRepository implements MembersRepository {
  final MembersRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  ApiMembersRepository({
    MembersRemoteDataSource? remoteDataSource,
    TokenStorage? tokenStorage,
    Dio? dio,
  })  : _remoteDataSource =
            remoteDataSource ?? MembersRemoteDataSourceImpl(dio: dio),
        _tokenStorage = tokenStorage ?? TokenStorage();

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

  @override
  Future<MemberDebtSummary> getDebtSummary(String memberId) async {
    final trimmedId = memberId.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError('Mã độc giả không được để trống');
    }

    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    final json = await _remoteDataSource.getDebtSummary(
      memberId: trimmedId,
      token: token,
    );

    return MemberDebtSummary.fromJson(json);
  }
}
