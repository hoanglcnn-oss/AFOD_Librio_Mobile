import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/members/data/api_members_repository.dart';
import 'package:week34_project/features/members/data/datasources/members_remote_data_source.dart';

void main() {
  group('MembersRemoteDataSourceImpl', () {
    test('getMembers gửi GET /members với search, page, limit', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'GET');
            expect(options.path, '/members');
            expect(options.queryParameters['search'], 'an@example.com');
            expect(options.queryParameters['page'], 1);
            expect(options.queryParameters['limit'], 100);

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': [
                    {
                      'id': 'mem-01',
                      'email': 'an@example.com',
                      'fullName': 'Nguyễn Văn An',
                      'cardNumber': 'LIB-2026-0001',
                      'status': 'ACTIVE',
                      'membershipExpiry': '2027-10-28T00:00:00.000Z',
                    },
                  ],
                  'meta': {'page': 1, 'totalPages': 1, 'hasNextPage': false},
                },
              ),
            );
          },
        ),
      );

      final dataSource = MembersRemoteDataSourceImpl(dio: dio);
      final result = await dataSource.getMembers(search: 'an@example.com');

      expect(result['data'], isA<List>());
      expect((result['data'] as List).length, 1);
    });
  });

  group('ApiMembersRepository', () {
    test('findByEmail trả về null nếu email rỗng', () async {
      final mockDataSource = _FakeMembersRemoteDataSource(pages: []);
      final repository = ApiMembersRepository(remoteDataSource: mockDataSource);

      final result = await repository.findByEmail('   ');
      expect(result, isNull);
    });

    test('findByEmail khớp email không phân biệt chữ hoa/thường', () async {
      final mockDataSource = _FakeMembersRemoteDataSource(
        pages: [
          {
            'data': [
              {
                'id': 'mem-01',
                'email': 'an@example.com',
                'fullName': 'Nguyễn Văn An',
                'cardNumber': 'LIB-2026-0001',
                'status': 'ACTIVE',
                'membershipExpiry': '2027-10-28T00:00:00.000Z',
              },
            ],
            'meta': {'page': 1, 'totalPages': 1, 'hasNextPage': false},
          },
        ],
      );

      final repository = ApiMembersRepository(remoteDataSource: mockDataSource);
      final member = await repository.findByEmail(' AN@EXAMPLE.COM ');

      expect(member, isNotNull);
      expect(member!.id, 'mem-01');
      expect(member.email, 'an@example.com');
    });

    test('findByEmail duyệt qua các trang phân trang để tìm', () async {
      final mockDataSource = _FakeMembersRemoteDataSource(
        pages: [
          // Trang 1 không khớp
          {
            'data': [
              {
                'id': 'mem-99',
                'email': 'other@example.com',
                'fullName': 'Người khác',
                'cardNumber': 'LIB-2026-0099',
                'status': 'ACTIVE',
                'membershipExpiry': '2027-10-28T00:00:00.000Z',
              },
            ],
            'meta': {'page': 1, 'totalPages': 2, 'hasNextPage': true},
          },
          // Trang 2 khớp
          {
            'data': [
              {
                'id': 'mem-02',
                'email': 'target@example.com',
                'fullName': 'Trần Thị B',
                'cardNumber': 'LIB-2026-0002',
                'status': 'ACTIVE',
                'membershipExpiry': '2027-10-28T00:00:00.000Z',
              },
            ],
            'meta': {'page': 2, 'totalPages': 2, 'hasNextPage': false},
          },
        ],
      );

      final repository = ApiMembersRepository(remoteDataSource: mockDataSource);
      final member = await repository.findByEmail('target@example.com');

      expect(member, isNotNull);
      expect(member!.id, 'mem-02');
      expect(mockDataSource.requestedPages, [1, 2]);
    });

    test(
      'findByEmail ném StateError nếu tìm thấy nhiều hơn 1 kết quả',
      () async {
        final mockDataSource = _FakeMembersRemoteDataSource(
          pages: [
            {
              'data': [
                {
                  'id': 'mem-01',
                  'email': 'duplicate@example.com',
                  'fullName': 'An',
                  'cardNumber': 'LIB-1',
                  'status': 'ACTIVE',
                  'membershipExpiry': '2027-10-28T00:00:00.000Z',
                },
                {
                  'id': 'mem-02',
                  'email': 'duplicate@example.com',
                  'fullName': 'An 2',
                  'cardNumber': 'LIB-2',
                  'status': 'ACTIVE',
                  'membershipExpiry': '2027-10-28T00:00:00.000Z',
                },
              ],
              'meta': {'page': 1, 'totalPages': 1, 'hasNextPage': false},
            },
          ],
        );

        final repository = ApiMembersRepository(
          remoteDataSource: mockDataSource,
        );

        expect(
          () => repository.findByEmail('duplicate@example.com'),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('findByEmail trả về null khi không có kết quả khớp', () async {
      final mockDataSource = _FakeMembersRemoteDataSource(
        pages: [
          {
            'data': [],
            'meta': {'page': 1, 'totalPages': 1, 'hasNextPage': false},
          },
        ],
      );

      final repository = ApiMembersRepository(remoteDataSource: mockDataSource);
      final member = await repository.findByEmail('notfound@example.com');

      expect(member, isNull);
    });
  });
}

class _FakeMembersRemoteDataSource implements MembersRemoteDataSource {
  final List<Map<String, dynamic>> pages;
  final List<int> requestedPages = [];

  _FakeMembersRemoteDataSource({required this.pages});

  @override
  Future<Map<String, dynamic>> getMembers({
    required String search,
    int page = 1,
    int limit = 100,
  }) async {
    requestedPages.add(page);
    final index = page - 1;
    if (index < pages.length) {
      return pages[index];
    }
    return {
      'data': [],
      'meta': {'page': page, 'totalPages': page, 'hasNextPage': false},
    };
  }
}
