import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:week34_project/app/app.dart';
import 'package:week34_project/core/constants/api_constants.dart';
import 'package:week34_project/core/network/dio_client.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';
import 'package:week34_project/features/auth/presentation/pages/login_screen.dart';
import 'package:week34_project/features/home/presentation/pages/member_main_screen.dart';

import 'fake/fake_auth_repository.dart';
import 'fake/fake_token_storage.dart';

class _Stub401Adapter implements HttpClientAdapter {
  final int statusCode;

  _Stub401Adapter({this.statusCode = 401});

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'message': 'Unauthorized'}),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  tearDown(() {
    DioClient.onUnauthorized = null;
  });

  group('DioClient 401 handling', () {
    test(
      'Gọi onUnauthorized khi API yêu cầu xác thực trả về 401',
      () async {
        var unauthorizedCount = 0;
        DioClient.onUnauthorized = () => unauthorizedCount++;

        final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
        dio.httpClientAdapter = _Stub401Adapter(statusCode: 401);
        dio.interceptors.add(DioClient.createAuthInterceptor());

        await expectLater(
          () => dio.get(
            ApiConstants.books,
            options: Options(headers: {'Authorization': 'Bearer expired-token'}),
          ),
          throwsA(isA<DioException>()),
        );

        expect(unauthorizedCount, 1);
      },
    );

    test(
      'Không gọi onUnauthorized khi /auth/login, /auth/register hoặc /auth/forgot-password trả về 401',
      () async {
        var unauthorizedCount = 0;
        DioClient.onUnauthorized = () => unauthorizedCount++;

        final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
        dio.httpClientAdapter = _Stub401Adapter(statusCode: 401);
        dio.interceptors.add(DioClient.createAuthInterceptor());

        for (final path in [
          ApiConstants.login,
          ApiConstants.register,
          ApiConstants.forgotPassword,
        ]) {
          await expectLater(
            () => dio.post(
              path,
              options: Options(headers: {'Authorization': 'Bearer some-token'}),
            ),
            throwsA(isA<DioException>()),
          );
        }

        expect(unauthorizedCount, 0);
      },
    );

    test(
      'Không gọi onUnauthorized khi request 401 không có Authorization header hoặc lỗi không phải 401',
      () async {
        var unauthorizedCount = 0;
        DioClient.onUnauthorized = () => unauthorizedCount++;

        final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
        dio.httpClientAdapter = _Stub401Adapter(statusCode: 401);
        dio.interceptors.add(DioClient.createAuthInterceptor());

        await expectLater(
          () => dio.get(ApiConstants.books),
          throwsA(isA<DioException>()),
        );

        dio.httpClientAdapter = _Stub401Adapter(statusCode: 403);
        await expectLater(
          () => dio.get(
            ApiConstants.books,
            options: Options(headers: {'Authorization': 'Bearer valid-token'}),
          ),
          throwsA(isA<DioException>()),
        );

        expect(unauthorizedCount, 0);
      },
    );
  });

  group('DofaApp session expiration integration', () {
    testWidgets(
      'Nhận 401 từ API yêu cầu xác thực -> xóa token, chuyển về LoginScreen và hiện thông báo hết hạn',
      (tester) async {
        final tokenStorage = FakeTokenStorage();
        await tokenStorage.saveToken('expired-token');

        final authBloc = AuthBloc(
          authRepository: FakeAuthRepository(),
          tokenStorage: tokenStorage,
        );
        addTearDown(authBloc.close);
        authBloc.emit(
          AuthAuthenticated(
            user: UserProfile(
              id: 'user-01',
              memberId: 'mem-01',
              email: 'test@librio.vn',
              phone: '0901234567',
              fullName: 'Test User',
              role: 'MEMBER',
              isActive: true,
              createdAt: DateTime(2026, 1, 1),
            ),
          ),
        );

        await tester.pumpWidget(DofaApp(authBloc: authBloc));
        await tester.pump();
        await tester.pump();

        expect(find.byType(MemberMainScreen), findsOneWidget);

        // Giả lập DioClient bắt được 401 từ API yêu cầu xác thực
        DioClient.onUnauthorized?.call();
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(tokenStorage.savedToken, isNull);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text(AuthBloc.sessionExpiredMessage), findsOneWidget);
      },
    );
  });
}
