import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';

class DioClient {
  DioClient._();

  static final Dio dio = _createDio();

  static Dio _createDio() {
    final client = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/json'},
      ),
    );

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
