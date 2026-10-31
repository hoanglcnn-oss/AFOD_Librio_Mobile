import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/data/api_auth_repository.dart';
import 'package:week34_project/features/auth/data/datasources/auth_remote_data_source.dart';

void main() {
  group('AuthRemoteDataSourceImpl', () {
    test('login gửi POST /auth/login với identifier và password', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'POST');
            expect(options.path, '/auth/login');

            final body = options.data as Map<String, dynamic>;
            expect(body['identifier'], 'user@example.com');
            expect(body['password'], 'secret123');

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'accessToken': 'jwt-123',
                  'tokenType': 'Bearer',
                  'expiresIn': 86400,
                  'user': {
                    'id': 'u1',
                    'email': 'user@example.com',
                    'phone': '0901234567',
                    'fullName': 'Nguyễn Văn A',
                    'role': 'MEMBER',
                    'isActive': true,
                    'createdAt': '2026-01-01T00:00:00.000Z',
                    'memberId': 'm1',
                  },
                },
              ),
            );
          },
        ),
      );

      final dataSource = AuthRemoteDataSourceImpl(dio: dio);
      final result = await dataSource.login(
        identifier: 'user@example.com',
        password: 'secret123',
      );

      expect(result['accessToken'], 'jwt-123');
      expect(result['user']['fullName'], 'Nguyễn Văn A');
    });

    test(
      'register gửi POST /auth/register với đầy đủ trường dữ liệu',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.method, 'POST');
              expect(options.path, '/auth/register');

              final body = options.data as Map<String, dynamic>;
              expect(body['fullName'], 'Nguyễn Văn A');
              expect(body['phone'], '0901234567');
              expect(body['email'], 'user@example.com');
              expect(body['password'], 'secret123');

              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'accessToken': 'jwt-reg',
                    'tokenType': 'Bearer',
                    'expiresIn': 86400,
                    'user': {
                      'id': 'u1',
                      'email': 'user@example.com',
                      'phone': '0901234567',
                      'fullName': 'Nguyễn Văn A',
                      'role': 'MEMBER',
                      'isActive': true,
                      'createdAt': '2026-01-01T00:00:00.000Z',
                    },
                  },
                ),
              );
            },
          ),
        );

        final dataSource = AuthRemoteDataSourceImpl(dio: dio);
        final result = await dataSource.register(
          fullName: 'Nguyễn Văn A',
          phone: '0901234567',
          email: 'user@example.com',
          password: 'secret123',
        );

        expect(result['accessToken'], 'jwt-reg');
      },
    );

    test('getCurrentUser gửi GET /auth/me kèm Authorization header', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'GET');
            expect(options.path, '/auth/me');
            expect(options.headers['Authorization'], 'Bearer my-token');

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'u1',
                  'email': 'user@example.com',
                  'phone': '0901234567',
                  'fullName': 'Nguyễn Văn A',
                  'role': 'MEMBER',
                  'isActive': true,
                  'createdAt': '2026-01-01T00:00:00.000Z',
                  'memberId': 'm1',
                },
              ),
            );
          },
        ),
      );

      final dataSource = AuthRemoteDataSourceImpl(dio: dio);
      final result = await dataSource.getCurrentUser('my-token');

      expect(result['id'], 'u1');
      expect(result['memberId'], 'm1');
    });
  });

  group('ApiAuthRepository', () {
    test('login parse kết quả sang AuthResponse', () async {
      final mockDataSource = _FakeAuthRemoteDataSource(
        authResponseData: {
          'accessToken': 'jwt-token',
          'tokenType': 'Bearer',
          'expiresIn': 3600,
          'user': {
            'id': 'u1',
            'email': 'user@example.com',
            'phone': '0901234567',
            'fullName': 'Nguyễn Văn A',
            'role': 'MEMBER',
            'isActive': true,
            'createdAt': '2026-01-01T00:00:00.000Z',
          },
        },
      );

      final repository = ApiAuthRepository(remoteDataSource: mockDataSource);
      final response = await repository.login('user@example.com', 'pass');

      expect(response.accessToken, 'jwt-token');
      expect(response.user.fullName, 'Nguyễn Văn A');
      expect(response.user.role, 'MEMBER');
    });

    test('getCurrentUser parse kết quả sang UserProfile', () async {
      final mockDataSource = _FakeAuthRemoteDataSource(
        userProfileData: {
          'id': 'u1',
          'email': 'user@example.com',
          'phone': '0901234567',
          'fullName': 'Nguyễn Văn A',
          'role': 'MEMBER',
          'isActive': true,
          'createdAt': '2026-01-01T00:00:00.000Z',
          'memberId': 'm1',
        },
      );

      final repository = ApiAuthRepository(remoteDataSource: mockDataSource);
      final profile = await repository.getCurrentUser('token');

      expect(profile.id, 'u1');
      expect(profile.memberId, 'm1');
      expect(profile.email, 'user@example.com');
    });
  });
}

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  final Map<String, dynamic>? authResponseData;
  final Map<String, dynamic>? userProfileData;

  _FakeAuthRemoteDataSource({this.authResponseData, this.userProfileData});

  @override
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    return authResponseData!;
  }

  @override
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    return authResponseData!;
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    return userProfileData!;
  }
}
