import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/data/api_auth_repository.dart';
import 'package:week34_project/features/auth/data/datasources/auth_remote_data_source.dart';

void main() {
  group('AuthRemoteDataSourceImpl', () {
    // Event | Điều kiện đầu vào | Kết quả được kiểm chứng
    test(
      'login | Thông tin đăng nhập hợp lệ | POST /auth/login, đúng identifier và password',
      () async {
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
      },
    );

    test(
      'register | Thông tin đăng ký đầy đủ | POST /auth/register, đúng request body',
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
    test(
      'forgotPassword | Email có khoảng trắng và chữ hoa | POST /auth/forgot-password, email được chuẩn hóa',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.method, 'POST');
              expect(options.path, '/auth/forgot-password');
              expect(options.data, {'email': 'user@example.com'});

              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message':
                        'Nếu email tồn tại, hướng dẫn đặt lại mật khẩu đã được gửi.',
                  },
                ),
              );
            },
          ),
        );

        final dataSource = AuthRemoteDataSourceImpl(dio: dio);

        final result = await dataSource.forgotPassword(
          email: '  USER@EXAMPLE.COM  ',
        );

        expect(result['success'], true);
      },
    );
    test(
      'getCurrentUser | Có JWT hợp lệ | GET /auth/me kèm Bearer token',
      () async {
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
      },
    );
  });

  group('ApiAuthRepository', () {
    test(
      'login | DataSource trả thông tin đăng nhập | parse đúng AuthResponse',
      () async {
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
      },
    );
    test(
      'forgotPassword | DataSource trả success | trả về thông báo chung',
      () async {
        final repository = ApiAuthRepository(
          remoteDataSource: _FakeAuthRemoteDataSource(),
        );

        final message = await repository.forgotPassword('user@example.com');

        expect(
          message,
          'Nếu email tồn tại, hướng dẫn đặt lại mật khẩu đã được gửi.',
        );
      },
    );
    test(
      'getCurrentUser | DataSource trả hồ sơ | parse đúng UserProfile',
      () async {
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
      },
    );
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
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    return {
      'success': true,
      'message': 'Nếu email tồn tại, hướng dẫn đặt lại mật khẩu đã được gửi.',
    };
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    return userProfileData!;
  }
}
