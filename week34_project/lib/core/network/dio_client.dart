import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';

class DioClient {
  DioClient._();

  static const Set<String> _unauthenticatedPaths = {
    ApiConstants.login,
    ApiConstants.register,
    ApiConstants.forgotPassword,
  };

  /// Callback được gọi khi một API yêu cầu xác thực trả về HTTP 401.
  static VoidCallback? onUnauthorized;

  static final Dio dio = _createDio();

  @visibleForTesting
  static bool shouldHandleUnauthorized(DioException error) {
    if (error.response?.statusCode != 401) {
      return false;
    }

    final path = error.requestOptions.path;
    final uriPath = error.requestOptions.uri.path;
    final isUnauthenticatedPath = _unauthenticatedPaths.any(
      (excluded) =>
          path == excluded ||
          uriPath == excluded ||
          uriPath.endsWith(excluded),
    );
    if (isUnauthenticatedPath) {
      return false;
    }

    final authHeader =
        error.requestOptions.headers['Authorization'] ??
        error.requestOptions.headers['authorization'];
    return authHeader != null && authHeader.toString().trim().isNotEmpty;
  }

  @visibleForTesting
  static Interceptor createAuthInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        if (shouldHandleUnauthorized(error)) {
          onUnauthorized?.call();
        }
        return handler.next(error);
      },
    );
  }

  static Dio _createDio() {
    final client = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );

    client.interceptors.add(createAuthInterceptor());

    if (kDebugMode) {
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final sanitizedHeaders = Map<String, dynamic>.from(options.headers);
            if (sanitizedHeaders.containsKey('Authorization')) {
              final auth = sanitizedHeaders['Authorization'].toString();
              sanitizedHeaders['Authorization'] = auth.length > 15
                  ? '${auth.substring(0, 15)}...[REDACTED]'
                  : '[REDACTED]';
            }

            debugPrint(
              '[HTTP REQUEST] ${options.method} ${options.uri} '
              'query=${options.queryParameters} headers=$sanitizedHeaders',
            );
            return handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint(
              '[HTTP RESPONSE] ${response.requestOptions.method} ${response.requestOptions.uri} '
              'status=${response.statusCode}',
            );
            return handler.next(response);
          },
          onError: (error, handler) {
            debugPrint(
              '[HTTP ERROR] ${error.requestOptions.method} ${error.requestOptions.uri} '
              'status=${error.response?.statusCode} errorType=${error.type} '
              'error=${error.error} message=${error.message} '
              'data=${error.response?.data}',
            );
            return handler.next(error);
          },
        ),
      );
    }

    return client;
  }
}
