import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

abstract class BorrowingsRemoteDataSource {
  Future<Map<String, dynamic>> createBorrowing({
    required Map<String, dynamic> data,
    required String token,
  });
  Future<Map<String, dynamic>> createBorrowingSlip({
    required Map<String, dynamic> data,
    required String token,
  });
  Future<Map<String, dynamic>> getBorrowings({
    required String memberId,
    required String token,
    int page = 1,
    int limit = 10,
  });

  Future<Map<String, dynamic>> getBorrowingSlips({
    required String memberId,
    required String token,
    int page = 1,
    int limit = 10,
  });

  Future<Map<String, dynamic>> getBorrowingSlipById({
    required String slipId,
    required String token,
  });

  Future<Map<String, dynamic>> getPendingBorrowingSlips({
    required String token,
    int page = 1,
    int limit = 10,
  });

  Future<Map<String, dynamic>> getAllBorrowingSlips({
    required String token,
    String? status,
    int page = 1,
    int limit = 10,
  });

  Future<Map<String, dynamic>> approveBorrowingSlip({
    required String slipId,
    required String token,
  });

  Future<Map<String, dynamic>> rejectBorrowingSlip({
    required String slipId,
    required String reason,
    required String token,
  });

  Future<Map<String, dynamic>> returnBook({
    required String borrowingId,
    required String token,
    Map<String, dynamic> data = const {},
  });

  Future<Map<String, dynamic>> returnSlipItems({
    required String slipId,
    required Map<String, dynamic> data,
    required String token,
  });

  Future<Map<String, dynamic>> renewLoan({
    required String borrowingId,
    required String token,
    required int extraDays,
    String? notes,
  });

  Future<Map<String, dynamic>> paySlipFine({
    required String slipId,
    required String token,
  });
}

class BorrowingsRemoteDataSourceImpl implements BorrowingsRemoteDataSource {
  final Dio _dio;

  BorrowingsRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.dio;

  @override
  Future<Map<String, dynamic>> createBorrowing({
    required Map<String, dynamic> data,
    required String token,
  }) async {
    final response = await _dio.post(
      ApiConstants.borrowings,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createBorrowingSlip({
    required Map<String, dynamic> data,
    required String token,
  }) async {
    final response = await _dio.post(
      ApiConstants.borrowingSlips,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getBorrowings({
    required String memberId,
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      ApiConstants.borrowings,
      queryParameters: {'memberId': memberId, 'page': page, 'limit': limit},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getBorrowingSlips({
    required String memberId,
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      ApiConstants.borrowingSlips,
      queryParameters: {'memberId': memberId, 'page': page, 'limit': limit},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getBorrowingSlipById({
    required String slipId,
    required String token,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.borrowingSlips}/$slipId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getPendingBorrowingSlips({
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      ApiConstants.borrowingSlips,
      queryParameters: {
        'status': 'PENDING_APPROVAL',
        'page': page,
        'limit': limit,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getAllBorrowingSlips({
    required String token,
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};

    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }

    final response = await _dio.get(
      ApiConstants.borrowingSlips,
      queryParameters: query,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> approveBorrowingSlip({
    required String slipId,
    required String token,
  }) async {
    final response = await _dio.patch(
      '${ApiConstants.borrowingSlips}/$slipId/approve',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> rejectBorrowingSlip({
    required String slipId,
    required String reason,
    required String token,
  }) async {
    final response = await _dio.patch(
      '${ApiConstants.borrowingSlips}/$slipId/reject',
      data: {'reason': reason},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> returnBook({
    required String borrowingId,
    required String token,
    Map<String, dynamic> data = const {},
  }) async {
    final response = await _dio.post(
      '${ApiConstants.borrowings}/$borrowingId/return',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> returnSlipItems({
    required String slipId,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.borrowingSlips}/$slipId/return-items',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> renewLoan({
    required String borrowingId,
    required String token,
    required int extraDays,
    String? notes,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.borrowings}/$borrowingId/renew',
      data: {
        'extraDays': extraDays,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> paySlipFine({
    required String slipId,
    required String token,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.borrowingSlips}/$slipId/pay-fine',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data as Map<String, dynamic>;
  }
}
