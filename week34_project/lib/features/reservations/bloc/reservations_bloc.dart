import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/paginated_reservations.dart';
import '../data/reservations_repository.dart';
import '../errors/reservation_error_mapper.dart';
import 'reservations_event.dart';
import 'reservations_state.dart';

class ReservationsBloc extends Bloc<ReservationsEvent, ReservationsState> {
  final ReservationsRepository reservationsRepository;

  ReservationsBloc({required this.reservationsRepository})
      : super(const ReservationsInitial()) {
    on<LoadReservations>(_onLoadReservations);
    on<RefreshReservations>(_onRefreshReservations);
    on<CancelReservationRequested>(_onCancelReservationRequested);
    on<CreateReservationRequested>(_onCreateReservationRequested);
  }

  Future<void> _onLoadReservations(
    LoadReservations event,
    Emitter<ReservationsState> emit,
  ) async {
    emit(const ReservationsLoading());

    try {
      final paginated = await reservationsRepository.getReservations(
        memberId: event.memberId,
        page: event.page,
        limit: event.limit,
      );

      emit(ReservationsLoaded(
        paginated: paginated,
        memberId: event.memberId,
      ));
    } catch (e) {
      emit(ReservationsFailure(
        ReservationErrorMapper.mapError(
          e,
          fallback: 'Không thể tải danh sách đặt trước.',
        ),
      ));
    }
  }

  Future<void> _onRefreshReservations(
    RefreshReservations event,
    Emitter<ReservationsState> emit,
  ) async {
    final current = state;
    final int page = switch (current) {
      ReservationsLoaded(:final paginated) => paginated.page,
      ReservationCancelling(:final paginated) => paginated.page,
      ReservationCancelSuccess(:final paginated) => paginated.page,
      ReservationCancelFailure(:final paginated) => paginated.page,
      _ => 1,
    };
    final int limit = switch (current) {
      ReservationsLoaded(:final paginated) => paginated.limit,
      ReservationCancelling(:final paginated) => paginated.limit,
      ReservationCancelSuccess(:final paginated) => paginated.limit,
      ReservationCancelFailure(:final paginated) => paginated.limit,
      _ => 10,
    };

    try {
      final paginated = await reservationsRepository.getReservations(
        memberId: event.memberId,
        page: page,
        limit: limit,
      );

      emit(ReservationsLoaded(
        paginated: paginated,
        memberId: event.memberId,
      ));
    } catch (e) {
      // Nếu đã có dữ liệu hiển thị, giữ dữ liệu cũ và có thể báo lỗi hoặc emit Failure nếu chưa có
      if (current is! ReservationsLoaded &&
          current is! ReservationCancelSuccess &&
          current is! ReservationCancelFailure) {
        emit(ReservationsFailure(
          ReservationErrorMapper.mapError(
            e,
            fallback: 'Không thể làm mới danh sách đặt trước.',
          ),
        ));
      }
    }
  }

  Future<void> _onCancelReservationRequested(
    CancelReservationRequested event,
    Emitter<ReservationsState> emit,
  ) async {
    if (state is ReservationCancelling) {
      // Tránh double submit
      return;
    }

    final currentPaginated = _extractCurrentPaginated();
    if (currentPaginated == null) {
      return;
    }

    emit(ReservationCancelling(
      paginated: currentPaginated,
      memberId: event.memberId,
      reservationId: event.reservationId,
    ));

    try {
      await reservationsRepository.cancelReservation(
        reservationId: event.reservationId,
        reason: event.reason,
      );

      // Sau khi hủy thành công, tải lại danh sách mới nhất từ Backend
      final refreshed = await reservationsRepository.getReservations(
        memberId: event.memberId,
        page: currentPaginated.page,
        limit: currentPaginated.limit,
      );

      emit(ReservationCancelSuccess(
        paginated: refreshed,
        memberId: event.memberId,
        message: 'Hủy đặt trước thành công',
      ));
    } catch (e) {
      if (ReservationErrorMapper.isTimeout(e)) {
        // Timeout: không tự retry mutation; kiểm tra lại backend
        try {
          final detail = await reservationsRepository.getReservationById(
            reservationId: event.reservationId,
          );

          if (detail.isCancelled) {
            final refreshed = await reservationsRepository.getReservations(
              memberId: event.memberId,
              page: currentPaginated.page,
              limit: currentPaginated.limit,
            );

            emit(ReservationCancelSuccess(
              paginated: refreshed,
              memberId: event.memberId,
              message: 'Đã xác nhận hủy đặt trước thành công',
            ));
            return;
          }
        } catch (_) {
          // Bỏ qua lỗi khi kiểm tra lại
        }

        emit(ReservationCancelFailure(
          paginated: currentPaginated,
          memberId: event.memberId,
          message:
              'Hết thời gian kết nối tới máy chủ. Vui lòng kiểm tra lại trạng thái.',
        ));
      } else {
        emit(ReservationCancelFailure(
          paginated: currentPaginated,
          memberId: event.memberId,
          message: ReservationErrorMapper.mapError(e),
        ));
      }
    }
  }

  Future<void> _onCreateReservationRequested(
    CreateReservationRequested event,
    Emitter<ReservationsState> emit,
  ) async {
    if (state is ReservationCreating) {
      return;
    }

    emit(ReservationCreating(bookId: event.bookId));

    try {
      final reservation = await reservationsRepository.createReservation(
        memberId: event.memberId,
        bookId: event.bookId,
        notes: event.notes,
      );

      final statusText = reservation.isReady
          ? 'Sách đã sẵn sàng nhận'
          : 'Đang chờ sách';

      emit(ReservationCreateSuccess(
        reservation: reservation,
        message: 'Đặt trước thành công ($statusText)',
      ));
    } catch (e) {
      if (ReservationErrorMapper.isTimeout(e)) {
        // Timeout: kiểm tra lại backend, không tự gọi lại POST
        try {
          final list = await reservationsRepository.getReservations(
            memberId: event.memberId,
            page: 1,
            limit: 10,
          );

          final found = list.items.where(
            (r) => r.bookId == event.bookId && (r.isPending || r.isReady),
          );

          if (found.isNotEmpty) {
            final res = found.first;
            final statusText =
                res.isReady ? 'Sách đã sẵn sàng nhận' : 'Đang chờ sách';
            emit(ReservationCreateSuccess(
              reservation: res,
              message: 'Đã xác nhận đặt trước ($statusText)',
            ));
            return;
          }
        } catch (_) {}

        emit(const ReservationCreateFailure(
          'Hết thời gian kết nối tới máy chủ. Vui lòng kiểm tra lại danh sách đặt trước.',
        ));
      } else {
        emit(ReservationCreateFailure(
          ReservationErrorMapper.mapError(e),
        ));
      }
    }
  }

  PaginatedReservations? _extractCurrentPaginated() {
    return switch (state) {
      ReservationsLoaded(:final paginated) => paginated,
      ReservationCancelling(:final paginated) => paginated,
      ReservationCancelSuccess(:final paginated) => paginated,
      ReservationCancelFailure(:final paginated) => paginated,
      _ => null,
    };
  }
}
