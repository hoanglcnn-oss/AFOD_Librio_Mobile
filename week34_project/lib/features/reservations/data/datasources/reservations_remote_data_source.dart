import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

abstract class ReservationsRemoteDataSource {
  Future<Map<String, dynamic>> createReservation({
    required Map<String, dynamic> data,
    required String token,
  });

  Future<Map<String, dynamic>> getReservations({
    required String memberId,
    required String token,
    int page = 1,
    int limit = 10,
  });

  Future<Map<String, dynamic>> getReservationById({
    required String reservationId,
    required String token,
  });

  Future<Map<String, dynamic>> cancelReservation({
    required String reservationId,
    required String token,
    String? reason,
  });
}

class ReservationsRemoteDataSourceImpl implements ReservationsRemoteDataSource {
  final Dio _dio;

  ReservationsRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.dio;

  @override
  Future<Map<String, dynamic>> createReservation({
    required Map<String, dynamic> data,
    required String token,
  }) async {
    final response = await _dio.post(
      ApiConstants.reservations,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getReservations({
    required String memberId,
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      ApiConstants.reservations,
      queryParameters: {'memberId': memberId, 'page': page, 'limit': limit},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getReservationById({
    required String reservationId,
    required String token,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.reservations}/$reservationId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> cancelReservation({
    required String reservationId,
    required String token,
    String? reason,
  }) async {
    final response = await _dio.patch(
      '${ApiConstants.reservations}/$reservationId/cancel',
      data: reason != null && reason.trim().isNotEmpty
          ? {'reason': reason.trim()}
          : <String, dynamic>{},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }
}
