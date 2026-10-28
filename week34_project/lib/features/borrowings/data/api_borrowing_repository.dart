import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'borrowing_repository.dart';
import 'models/borrowing.dart';
import 'models/create_borrowing_request.dart';

class ApiBorrowingRepository implements BorrowingRepository {
  final Dio _dio;

  ApiBorrowingRepository({Dio? dio}) : _dio = dio ?? DioClient.dio;

  @override
  Future<Borrowing> borrowBook(CreateBorrowingRequest request) async {
    final response = await _dio.post(
      ApiConstants.borrowings,
      data: request.toJson(),
    );

    return Borrowing.fromJson(response.data as Map<String, dynamic>);
  }
}
