import 'package:dio/dio.dart';
import '../../../../core/storage/token_storage.dart';
import 'datasources/reservations_remote_data_source.dart';
import 'models/paginated_reservations.dart';
import 'models/reservation.dart';
import 'reservations_repository.dart';

class ApiReservationsRepository implements ReservationsRepository {
  final ReservationsRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  ApiReservationsRepository({
    ReservationsRemoteDataSource? remoteDataSource,
    TokenStorage? tokenStorage,
    Dio? dio,
  })  : _remoteDataSource =
            remoteDataSource ?? ReservationsRemoteDataSourceImpl(dio: dio),
        _tokenStorage = tokenStorage ?? TokenStorage();

  @override
  Future<Reservation> createReservation({
    required String memberId,
    required String bookId,
    String? notes,
  }) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    if (memberId.trim().isEmpty) {
      throw ArgumentError('Mã độc giả không được để trống');
    }

    if (bookId.trim().isEmpty) {
      throw ArgumentError('Mã sách không được để trống');
    }

    final body = <String, dynamic>{
      'memberId': memberId.trim(),
      'bookId': bookId.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final data = await _remoteDataSource.createReservation(
      data: body,
      token: token,
    );

    return Reservation.fromJson(data);
  }

  @override
  Future<PaginatedReservations> getReservations({
    required String memberId,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    if (memberId.trim().isEmpty) {
      throw ArgumentError('Mã độc giả không được để trống');
    }

    final data = await _remoteDataSource.getReservations(
      memberId: memberId.trim(),
      token: token,
      page: page,
      limit: limit,
    );

    return PaginatedReservations.fromJson(data);
  }

  @override
  Future<Reservation> getReservationById({
    required String reservationId,
  }) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    if (reservationId.trim().isEmpty) {
      throw ArgumentError('Mã đặt trước không được để trống');
    }

    final data = await _remoteDataSource.getReservationById(
      reservationId: reservationId.trim(),
      token: token,
    );

    return Reservation.fromJson(data);
  }

  @override
  Future<Reservation> cancelReservation({
    required String reservationId,
    String? reason,
  }) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    if (reservationId.trim().isEmpty) {
      throw ArgumentError('Mã đặt trước không được để trống');
    }

    final data = await _remoteDataSource.cancelReservation(
      reservationId: reservationId.trim(),
      token: token,
      reason: reason?.trim(),
    );

    return Reservation.fromJson(data);
  }
}
