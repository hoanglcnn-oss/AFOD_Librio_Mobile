import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/members/data/api_members_repository.dart';
import 'package:week34_project/features/members/data/datasources/members_remote_data_source.dart';
import 'package:week34_project/features/members/data/models/member_debt_summary.dart';

import 'fake/fake_token_storage.dart';

class _FakeMembersRemoteDataSource implements MembersRemoteDataSource {
  final Map<String, dynamic>? responseData;
  final Exception? errorToThrow;
  String? lastMemberId;
  String? lastToken;
  int getDebtSummaryCallCount = 0;

  _FakeMembersRemoteDataSource({this.responseData, this.errorToThrow});

  @override
  Future<Map<String, dynamic>> getMembers({
    required String search,
    int page = 1,
    int limit = 100,
  }) async {
    return {
      'data': [],
      'meta': {'page': 1, 'totalPages': 1, 'hasNextPage': false},
    };
  }

  @override
  Future<Map<String, dynamic>> getDebtSummary({
    required String memberId,
    required String token,
  }) async {
    getDebtSummaryCallCount++;
    lastMemberId = memberId;
    lastToken = token;

    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    return responseData ??
        {
          'maxBorrowLimit': 5,
          'currentBorrowedCount': 2,
          'remainingBorrowLimit': 3,
          'canBorrow': true,
          'overdueCount': 0,
          'unpaidFineAmount': 0,
        };
  }
}

void main() {
  group('MembersRemoteDataSourceImpl.getDebtSummary', () {
    test(
      'Gọi GET /members/:memberId/debt-summary với Authorization header',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.method, 'GET');
              expect(options.path, '/members/mem-123/debt-summary');
              expect(options.headers['Authorization'], 'Bearer mock-jwt-token');

              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'maxBorrowLimit': 5,
                    'currentBorrowedCount': 3,
                    'remainingBorrowLimit': 2,
                    'canBorrow': true,
                    'reasonIfNotAllowed': null,
                    'overdueCount': 0,
                    'unpaidFineAmount': 0,
                  },
                ),
              );
            },
          ),
        );

        final dataSource = MembersRemoteDataSourceImpl(dio: dio);
        final result = await dataSource.getDebtSummary(
          memberId: 'mem-123',
          token: 'mock-jwt-token',
        );

        expect(result['maxBorrowLimit'], 5);
        expect(result['currentBorrowedCount'], 3);
        expect(result['remainingBorrowLimit'], 2);
        expect(result['canBorrow'], isTrue);
      },
    );
  });

  group('ApiMembersRepository.getDebtSummary', () {
    late FakeTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = FakeTokenStorage()..savedToken = 'valid-token';
    });

    test('Lấy thông tin thành công khi có token và memberId hợp lệ', () async {
      final remoteDataSource = _FakeMembersRemoteDataSource(
        responseData: {
          'maxBorrowLimit': 5,
          'currentBorrowedCount': 1,
          'remainingBorrowLimit': 4,
          'canBorrow': true,
          'overdueCount': 0,
          'unpaidFineAmount': 0,
        },
      );

      final repository = ApiMembersRepository(
        remoteDataSource: remoteDataSource,
        tokenStorage: tokenStorage,
      );

      final summary = await repository.getDebtSummary('mem-01');

      expect(summary, isA<MemberDebtSummary>());
      expect(summary.currentBorrowedCount, 1);
      expect(summary.remainingBorrowLimit, 4);
      expect(remoteDataSource.lastMemberId, 'mem-01');
      expect(remoteDataSource.lastToken, 'valid-token');
      expect(remoteDataSource.getDebtSummaryCallCount, 1);
    });

    test('Throw ArgumentError khi memberId rỗng', () async {
      final repository = ApiMembersRepository(
        remoteDataSource: _FakeMembersRemoteDataSource(),
        tokenStorage: tokenStorage,
      );

      expect(
        () => repository.getDebtSummary('   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Throw StateError khi không có token (chưa đăng nhập)', () async {
      tokenStorage.savedToken = null;

      final repository = ApiMembersRepository(
        remoteDataSource: _FakeMembersRemoteDataSource(),
        tokenStorage: tokenStorage,
      );

      expect(
        () => repository.getDebtSummary('mem-01'),
        throwsA(isA<StateError>()),
      );
    });

    test('Truyền ngoại lệ từ remoteDataSource khi gặp lỗi API', () async {
      final remoteDataSource = _FakeMembersRemoteDataSource(
        errorToThrow: DioException(
          requestOptions: RequestOptions(path: '/members/mem-01/debt-summary'),
          response: Response(
            requestOptions: RequestOptions(
              path: '/members/mem-01/debt-summary',
            ),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final repository = ApiMembersRepository(
        remoteDataSource: remoteDataSource,
        tokenStorage: tokenStorage,
      );

      expect(
        () => repository.getDebtSummary('mem-01'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
