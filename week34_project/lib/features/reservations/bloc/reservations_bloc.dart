import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/paginated_reservations.dart';
import '../data/reservations_repository.dart';
import '../errors/reservation_error_mapper.dart';
import 'reservations_event.dart';
import 'reservations_state.dart';

class ReservationsBloc extends Bloc<ReservationsEvent, ReservationsState> {
  final ReservationsRepository reservationsRepository;
  int _activeRequestId = 0;

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
    if (state is ReservationCancelling || state is ReservationCreating) {
      // Không ngắt quãng mutation đang xử lý
      return;
    }

    final reqId = ++_activeRequestId;
    emit(const ReservationsLoading());

    try {
      final paginated = await reservationsRepository.getReservations(
        memberId: event.memberId,
        page: event.page,
        limit: event.limit,
      );

      if (reqId != _activeRequestId) {
        // Response cũ, bỏ qua để tránh ghi đè dữ liệu mới
        return;
      }

      emit(ReservationsLoaded(
        paginated: paginated,
        memberId: event.memberId,
      ));
    } catch (e) {
      if (reqId != _activeRequestId) return;

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

    final reqId = ++_activeRequestId;

    try {
      final paginated = await reservationsRepository.getReservations(
        memberId: event.memberId,
        page: page,
        limit: limit,
      );

      if (reqId != _activeRequestId) {
        return;
      }

      emit(ReservationsLoaded(
        paginated: paginated,
        memberId: event.memberId,
      ));
    } catch (e) {
      if (reqId != _activeRequestId) return;

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
    } finally {
      event.completer?.complete();
    }
  }

  Future<void> _onCancelReservationRequested(
    CancelReservationRequested event,
    Emitter<ReservationsState> emit,
  ) async {
    if (state is ReservationCancelling || state is ReservationCreating) {
      // Chống mutation trùng / double submit
      return;
    }

    final currentPaginated = _extractCurrentPaginated();
    if (currentPaginated == null) {
      return;
    }

    final mutationId = ++_activeRequestId;

    emit(ReservationCancelling(
      paginated: currentPaginated,
      memberId: event.memberId,
      reservationId: event.reservationId,
    ));

    try {
      final cancelledReservation =
          await reservationsRepository.cancelReservation(
        reservationId: event.reservationId,
        reason: event.reason,
      );

      // Sau khi PATCH cancel thành công:
      final refreshId = ++_activeRequestId;
      try {
        final refreshed = await reservationsRepository.getReservations(
          memberId: event.memberId,
          page: currentPaginated.page,
          limit: currentPaginated.limit,
        );

        if (refreshId != _activeRequestId) return;

        emit(ReservationCancelSuccess(
          paginated: refreshed,
          memberId: event.memberId,
          message: 'Hủy đặt trước thành công',
        ));
      } catch (_) {
        // PATCH cancel thành công nhưng GET refresh lỗi vẫn phải báo hủy thành công, giữ dữ liệu Backend đã trả
        if (refreshId != _activeRequestId && mutationId != _activeRequestId) {
          return;
        }

        final updatedItems = currentPaginated.items.map((r) {
          return r.id == event.reservationId ? cancelledReservation : r;
        }).toList();

        final optimisticPaginated = PaginatedReservations(
          items: updatedItems,
          page: currentPaginated.page,
          limit: currentPaginated.limit,
          totalItems: currentPaginated.totalItems,
          totalPages: currentPaginated.totalPages,
          hasNextPage: currentPaginated.hasNextPage,
        );

        emit(ReservationCancelSuccess(
          paginated: optimisticPaginated,
          memberId: event.memberId,
          message: 'Hủy đặt trước thành công',
        ));
      }
    } catch (e) {
      if (ReservationErrorMapper.isTimeout(e)) {
        // Timeout: KHÔNG TỰ RETRY MUTATION; kiểm tra lại backend
        try {
          final detail = await reservationsRepository.getReservationById(
            reservationId: event.reservationId,
          );

          if (detail.isCancelled) {
            final refreshId = ++_activeRequestId;
            try {
              final refreshed = await reservationsRepository.getReservations(
                memberId: event.memberId,
                page: currentPaginated.page,
                limit: currentPaginated.limit,
              );

              if (refreshId != _activeRequestId) return;

              emit(ReservationCancelSuccess(
                paginated: refreshed,
                memberId: event.memberId,
                message: 'Đã xác nhận hủy đặt trước thành công',
              ));
              return;
            } catch (_) {
              final updatedItems = currentPaginated.items.map((r) {
                return r.id == event.reservationId ? detail : r;
              }).toList();

              emit(ReservationCancelSuccess(
                paginated: PaginatedReservations(
                  items: updatedItems,
                  page: currentPaginated.page,
                  limit: currentPaginated.limit,
                  totalItems: currentPaginated.totalItems,
                  totalPages: currentPaginated.totalPages,
                  hasNextPage: currentPaginated.hasNextPage,
                ),
                memberId: event.memberId,
                message: 'Đã xác nhận hủy đặt trước thành công',
              ));
              return;
            }
          }
        } catch (_) {}

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
    if (state is ReservationCreating || state is ReservationCancelling) {
      // Chống mutation trùng / double submit
      return;
    }

    final mutationId = ++_activeRequestId;
    emit(ReservationCreating(bookId: event.bookId));

    final requestStartTime = DateTime.now();

    try {
      final reservation = await reservationsRepository.createReservation(
        memberId: event.memberId,
        bookId: event.bookId,
        notes: event.notes,
      );

      final statusText = reservation.isReady
          ? 'Sách đã sẵn sàng nhận'
          : 'Đang chờ sách';

      if (mutationId != _activeRequestId) return;

      emit(ReservationCreateSuccess(
        reservation: reservation,
        message: 'Đặt trước thành công ($statusText)',
      ));
    } catch (e) {
      if (mutationId != _activeRequestId) return;
      if (ReservationErrorMapper.isTimeout(e)) {
        // Timeout: KHÔNG TỰ RETRY POST
        try {
          final list = await reservationsRepository.getReservations(
            memberId: event.memberId,
            page: 1,
            limit: 10,
          );

          // Chỉ xác nhận thành công nếu tìm thấy một reservation MỚI được tạo sau thời điểm request
          // KHÔNG khẳng định POST timeout thành công chỉ vì thấy một reservation cũ cùng bookId trong trang đầu!
          final newlyCreated = list.items.where((r) {
            if (r.bookId != event.bookId) return false;
            if (!r.isPending && !r.isReady) return false;
            if (r.reservedAt == null) return false;
            return r.reservedAt!.isAfter(
              requestStartTime.subtract(const Duration(seconds: 5)),
            );
          }).toList();

          if (newlyCreated.isNotEmpty) {
            final res = newlyCreated.first;
            final statusText =
                res.isReady ? 'Sách đã sẵn sàng nhận' : 'Đang chờ sách';
            emit(ReservationCreateSuccess(
              reservation: res,
              message: 'Đã xác nhận đặt trước ($statusText)',
            ));
            return;
          }
        } catch (_) {}

        // Hiển thị kết quả chưa xác định khi không xác minh được, hướng người dùng kiểm tra danh sách
        emit(const ReservationCreateFailure(
          'Kết quả đặt trước chưa được xác định do mất kết nối. Vui lòng kiểm tra lại trong danh sách đặt trước.',
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
