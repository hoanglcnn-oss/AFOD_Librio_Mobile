import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/core/constants/api_constants.dart';
import 'package:week34_project/features/borrowing/reservations/data/api_reservations_repository.dart';
import 'package:week34_project/features/borrowing/reservations/data/datasources/reservations_remote_data_source.dart';
import 'package:week34_project/features/borrowing/reservations/errors/reservation_error_mapper.dart';

import 'fake/fake_token_storage.dart';

class FakeReservationsRemoteDataSource implements ReservationsRemoteDataSource {
  Map<String, dynamic>? lastCreatedData;
  String? lastToken;
  String? lastGetMemberId;
  int? lastGetPage;
  int? lastGetLimit;
  String? lastGetId;
  String? lastCancelId;
  String? lastCancelReason;

  Map<String, dynamic> fakeCreateResponse = {
    'id': 'res-10',
    'reservationCode': 'RSV-10',
    'memberId': 'mem-10',
    'bookId': 'b-10',
    'bookTitle': 'Dart in Action',
    'status': 'PENDING',
    'reservedAt': '2026-11-13T10:00:00Z',
  };

  Map<String, dynamic> fakeGetResponse = {
    'data': [
      {
        'id': 'res-10',
        'reservationCode': 'RSV-10',
        'memberId': 'mem-10',
        'bookId': 'b-10',
        'bookTitle': 'Dart in Action',
        'status': 'PENDING',
        'reservedAt': '2026-11-13T10:00:00Z',
      }
    ],
    'meta': {
      'page': 1,
      'limit': 10,
      'totalItems': 1,
      'totalPages': 1,
      'hasNextPage': false,
    }
  };

  Map<String, dynamic> fakeDetailResponse = {
    'id': 'res-10',
    'reservationCode': 'RSV-10',
    'memberId': 'mem-10',
    'bookId': 'b-10',
    'bookTitle': 'Dart in Action',
    'status': 'READY',
    'reservedAt': '2026-11-13T10:00:00Z',
    'expiresAt': '2026-11-16T18:00:00Z',
  };

  Map<String, dynamic> fakeCancelResponse = {
    'id': 'res-10',
    'reservationCode': 'RSV-10',
    'memberId': 'mem-10',
    'bookId': 'b-10',
    'bookTitle': 'Dart in Action',
    'status': 'CANCELLED',
    'reservedAt': '2026-11-13T10:00:00Z',
    'cancellationReason': 'Changed mind',
  };

  @override
  Future<Map<String, dynamic>> createReservation({
    required Map<String, dynamic> data,
    required String token,
  }) async {
    lastCreatedData = data;
    lastToken = token;
    return fakeCreateResponse;
  }

  @override
  Future<Map<String, dynamic>> getReservations({
    required String memberId,
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    lastGetMemberId = memberId;
    lastToken = token;
    lastGetPage = page;
    lastGetLimit = limit;
    return fakeGetResponse;
  }

  @override
  Future<Map<String, dynamic>> getReservationById({
    required String reservationId,
    required String token,
  }) async {
    lastGetId = reservationId;
    lastToken = token;
    return fakeDetailResponse;
  }

  @override
  Future<Map<String, dynamic>> cancelReservation({
    required String reservationId,
    required String token,
    String? reason,
  }) async {
    lastCancelId = reservationId;
    lastToken = token;
    lastCancelReason = reason;
    return fakeCancelResponse;
  }
}

void main() {
  group('ApiReservationsRepository', () {
    late FakeReservationsRemoteDataSource remoteDataSource;
    late FakeTokenStorage tokenStorage;
    late ApiReservationsRepository repository;

    setUp(() {
      remoteDataSource = FakeReservationsRemoteDataSource();
      tokenStorage = FakeTokenStorage()..savedToken = 'valid-jwt-token';
      repository = ApiReservationsRepository(
        remoteDataSource: remoteDataSource,
        tokenStorage: tokenStorage,
      );
    });

    test('createReservation sends memberId, bookId, notes, and token', () async {
      final res = await repository.createReservation(
        memberId: 'mem-10',
        bookId: 'b-10',
        notes: 'Cần gấp trước thứ sáu',
      );

      expect(remoteDataSource.lastToken, 'valid-jwt-token');
      expect(remoteDataSource.lastCreatedData?['memberId'], 'mem-10');
      expect(remoteDataSource.lastCreatedData?['bookId'], 'b-10');
      expect(remoteDataSource.lastCreatedData?['notes'], 'Cần gấp trước thứ sáu');
      expect(res.id, 'res-10');
      expect(res.reservationCode, 'RSV-10');
      expect(res.reservedAt, DateTime.parse('2026-11-13T10:00:00Z'));
      expect(res.bookTitle, 'Dart in Action');
    });

    test('createReservation throws StateError when token is null or empty', () async {
      tokenStorage = FakeTokenStorage()..savedToken = null;
      repository = ApiReservationsRepository(
        remoteDataSource: remoteDataSource,
        tokenStorage: tokenStorage,
      );

      expect(
        () => repository.createReservation(
          memberId: 'mem-1',
          bookId: 'b-1',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('createReservation throws ArgumentError on empty memberId or bookId', () async {
      expect(
        () => repository.createReservation(
          memberId: '',
          bookId: 'b-1',
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => repository.createReservation(
          memberId: 'mem-1',
          bookId: '  ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getReservations sends pagination and memberId query', () async {
      final result = await repository.getReservations(
        memberId: 'mem-10',
        page: 2,
        limit: 5,
      );

      expect(remoteDataSource.lastGetMemberId, 'mem-10');
      expect(remoteDataSource.lastGetPage, 2);
      expect(remoteDataSource.lastGetLimit, 5);
      expect(remoteDataSource.lastToken, 'valid-jwt-token');
      expect(result.items.length, 1);
    });

    test('getReservationById fetches detail with token', () async {
      final res = await repository.getReservationById(
        reservationId: 'res-10',
      );

      expect(remoteDataSource.lastGetId, 'res-10');
      expect(remoteDataSource.lastToken, 'valid-jwt-token');
      expect(res.isReady, isTrue);
    });

    test('cancelReservation sends cancel request with reason and token', () async {
      final res = await repository.cancelReservation(
        reservationId: 'res-10',
        reason: 'Không cần nữa',
      );

      expect(remoteDataSource.lastCancelId, 'res-10');
      expect(remoteDataSource.lastCancelReason, 'Không cần nữa');
      expect(remoteDataSource.lastToken, 'valid-jwt-token');
      expect(res.isCancelled, isTrue);
    });
  });

  group('ReservationErrorMapper', () {
    test('Identifies timeouts correctly', () {
      final connTimeout = DioException(
        requestOptions: RequestOptions(path: ApiConstants.reservations),
        type: DioExceptionType.connectionTimeout,
      );
      final sendTimeout = DioException(
        requestOptions: RequestOptions(path: ApiConstants.reservations),
        type: DioExceptionType.sendTimeout,
      );
      final receiveTimeout = DioException(
        requestOptions: RequestOptions(path: ApiConstants.reservations),
        type: DioExceptionType.receiveTimeout,
      );
      final badResponse = DioException(
        requestOptions: RequestOptions(path: ApiConstants.reservations),
        type: DioExceptionType.badResponse,
      );

      expect(ReservationErrorMapper.isTimeout(connTimeout), isTrue);
      expect(ReservationErrorMapper.isTimeout(sendTimeout), isTrue);
      expect(ReservationErrorMapper.isTimeout(receiveTimeout), isTrue);
      expect(ReservationErrorMapper.isTimeout(badResponse), isFalse);
      expect(ReservationErrorMapper.isTimeout(Exception()), isFalse);
    });

    test('Maps HTTP 409 Conflict with backend message or fallback', () {
      final conflictWithMsg = DioException(
        requestOptions: RequestOptions(path: ApiConstants.reservations),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.reservations),
          statusCode: 409,
          data: {'message': 'Độc giả đã đặt trước sách này rồi'},
        ),
      );

      final mapped = ReservationErrorMapper.mapError(conflictWithMsg);
      expect(mapped, 'Độc giả đã đặt trước sách này rồi');

      final conflictDefault = DioException(
        requestOptions: RequestOptions(path: ApiConstants.reservations),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.reservations),
          statusCode: 409,
          data: {},
        ),
      );
      expect(
        ReservationErrorMapper.mapError(conflictDefault),
        'Bạn đã có lượt đặt trước đang chờ cho sách này.',
      );
    });

    test('Maps HTTP 400 Bad Request with validation list or string', () {
      final badRequest = DioException(
        requestOptions: RequestOptions(path: ApiConstants.reservations),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.reservations),
          statusCode: 400,
          data: {
            'message': ['Mã sách không hợp lệ', 'Ghi chú quá dài'],
          },
        ),
      );

      expect(
        ReservationErrorMapper.mapError(badRequest),
        'Mã sách không hợp lệ, Ghi chú quá dài',
      );
    });

    test('Maps HTTP 403 Forbidden', () {
      final forbidden = DioException(
        requestOptions: RequestOptions(path: ApiConstants.reservations),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.reservations),
          statusCode: 403,
          data: {},
        ),
      );

      expect(
        ReservationErrorMapper.mapError(forbidden),
        'Bạn không có quyền thực hiện thao tác này.',
      );
    });

    test('Maps connection error', () {
      final connErr = DioException(
        requestOptions: RequestOptions(path: ApiConstants.reservations),
        type: DioExceptionType.connectionError,
      );

      expect(
        ReservationErrorMapper.mapError(connErr),
        'Lỗi kết nối mạng, vui lòng kiểm tra đường truyền.',
      );
    });
  });
}
