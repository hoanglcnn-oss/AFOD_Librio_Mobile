import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/paginated_reservations.dart';
import '../data/reservations_repository.dart';
import '../errors/reservation_error_mapper.dart';
import 'reservations_event.dart';
import 'reservations_state.dart';

class ReservationsBloc extends Bloc<ReservationsEvent, ReservationsState> {
  final ReservationsRepository reservationsRepository;

  // Quản lý riêng biệt request đọc và ghi để tránh race condition
  int _readRequestId = 0;
  int _writeEpoch = 0;
  bool _isMutating = false;
  final Set<String> _cancelledReservationIds = {};

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
    if (_isMutating ||
        state is ReservationCancelling ||
        state is ReservationCreating) {
      // Không ngắt quãng mutation đang xử lý
      return;
    }

    final reqReadId = ++_readRequestId;
    final reqWriteEpoch = _writeEpoch;
    emit(const ReservationsLoading());

    try {
      final paginated = await reservationsRepository.getReservations(
        memberId: event.memberId,
        page: event.page,
        limit: event.limit,
      );

      // Nếu có mutation diễn ra hoặc có request đọc mới hơn: bỏ qua response cũ
      if (reqReadId != _readRequestId ||
          reqWriteEpoch != _writeEpoch ||
          _isMutating) {
        return;
      }

      final reconciledItems = paginated.items.map((r) {
        if (_cancelledReservationIds.contains(r.id)) {
          return r.copyWith(status: 'CANCELLED');
        }
        return r;
      }).toList();

      final reconciledPaginated = PaginatedReservations(
        items: reconciledItems,
        page: paginated.page,
        limit: paginated.limit,
        totalItems: paginated.totalItems,
        totalPages: paginated.totalPages,
        hasNextPage: paginated.hasNextPage,
      );

      emit(ReservationsLoaded(
        paginated: reconciledPaginated,
        memberId: event.memberId,
      ));
    } catch (e) {
      if (reqReadId != _readRequestId ||
          reqWriteEpoch != _writeEpoch ||
          _isMutating) {
        return;
      }

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
    if (_isMutating ||
        state is ReservationCancelling ||
        state is ReservationCreating) {
      event.completer?.complete();
      return;
    }

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

    final reqReadId = ++_readRequestId;
    final reqWriteEpoch = _writeEpoch;

    try {
      final paginated = await reservationsRepository.getReservations(
        memberId: event.memberId,
        page: page,
        limit: limit,
      );

      // Bỏ qua nếu có mutation đang chạy hoặc đã có thay đổi mutation mới hơn
      if (reqReadId != _readRequestId ||
          reqWriteEpoch != _writeEpoch ||
          _isMutating) {
        return;
      }

      final reconciledItems = paginated.items.map((r) {
        if (_cancelledReservationIds.contains(r.id)) {
          return r.copyWith(status: 'CANCELLED');
        }
        return r;
      }).toList();

      final reconciledPaginated = PaginatedReservations(
        items: reconciledItems,
        page: paginated.page,
        limit: paginated.limit,
        totalItems: paginated.totalItems,
        totalPages: paginated.totalPages,
        hasNextPage: paginated.hasNextPage,
      );

      emit(ReservationsLoaded(
        paginated: reconciledPaginated,
        memberId: event.memberId,
      ));
    } catch (e) {
      if (reqReadId != _readRequestId ||
          reqWriteEpoch != _writeEpoch ||
          _isMutating) {
        return;
      }

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
    if (_isMutating ||
        state is ReservationCancelling ||
        state is ReservationCreating) {
      // Chống mutation trùng / double submit
      return;
    }

    final currentPaginated = _extractCurrentPaginated();
    if (currentPaginated == null) {
      return;
    }

    _isMutating = true;
    ++_writeEpoch;

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

      _cancelledReservationIds.add(event.reservationId);

      // Cập nhật optimistic từ kết quả PATCH thành công
      final updatedItems = currentPaginated.items.map((r) {
        return r.id == event.reservationId ? cancelledReservation : r;
      }).toList();

      PaginatedReservations finalPaginated = PaginatedReservations(
        items: updatedItems,
        page: currentPaginated.page,
        limit: currentPaginated.limit,
        totalItems: currentPaginated.totalItems,
        totalPages: currentPaginated.totalPages,
        hasNextPage: currentPaginated.hasNextPage,
      );

      // Cố gắng refresh thêm từ backend nhưng GET refresh không được làm mất ReservationCancelSuccess
      try {
        final refreshed = await reservationsRepository.getReservations(
          memberId: event.memberId,
          page: currentPaginated.page,
          limit: currentPaginated.limit,
        );

        final reconciled = refreshed.items.map((r) {
          return r.id == event.reservationId ? cancelledReservation : r;
        }).toList();

        finalPaginated = PaginatedReservations(
          items: reconciled,
          page: refreshed.page,
          limit: refreshed.limit,
          totalItems: refreshed.totalItems,
          totalPages: refreshed.totalPages,
          hasNextPage: refreshed.hasNextPage,
        );
      } catch (_) {
        // Giữ nguyên finalPaginated đã cập nhật từ PATCH thành công
      }

      // Luôn phát ReservationCancelSuccess khi PATCH thành công
      emit(ReservationCancelSuccess(
        paginated: finalPaginated,
        memberId: event.memberId,
        message: 'Hủy đặt trước thành công',
      ));
    } catch (e) {
      if (ReservationErrorMapper.isTimeout(e)) {
        // Timeout: KHÔNG TỰ RETRY MUTATION; kiểm tra lại backend
        try {
          final detail = await reservationsRepository.getReservationById(
            reservationId: event.reservationId,
          );

          if (detail.isCancelled) {
            _cancelledReservationIds.add(event.reservationId);
            final updatedItems = currentPaginated.items.map((r) {
              return r.id == event.reservationId ? detail : r;
            }).toList();

            PaginatedReservations finalPaginated = PaginatedReservations(
              items: updatedItems,
              page: currentPaginated.page,
              limit: currentPaginated.limit,
              totalItems: currentPaginated.totalItems,
              totalPages: currentPaginated.totalPages,
              hasNextPage: currentPaginated.hasNextPage,
            );

            try {
              final refreshed = await reservationsRepository.getReservations(
                memberId: event.memberId,
                page: currentPaginated.page,
                limit: currentPaginated.limit,
              );

              final reconciled = refreshed.items.map((r) {
                return r.id == event.reservationId ? detail : r;
              }).toList();

              finalPaginated = PaginatedReservations(
                items: reconciled,
                page: refreshed.page,
                limit: refreshed.limit,
                totalItems: refreshed.totalItems,
                totalPages: refreshed.totalPages,
                hasNextPage: refreshed.hasNextPage,
              );
            } catch (_) {}

            emit(ReservationCancelSuccess(
              paginated: finalPaginated,
              memberId: event.memberId,
              message: 'Đã xác nhận hủy đặt trước thành công',
            ));
            return;
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
    } finally {
      _isMutating = false;
    }
  }

  Future<void> _onCreateReservationRequested(
    CreateReservationRequested event,
    Emitter<ReservationsState> emit,
  ) async {
    if (_isMutating ||
        state is ReservationCreating ||
        state is ReservationCancelling) {
      // Chống mutation trùng / double submit
      return;
    }

    _isMutating = true;
    ++_writeEpoch;
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
        // Timeout: KHÔNG TỰ RETRY POST
        // Không coi reservation có reservedAt gần requestStartTime là bằng chứng chắc chắn POST vừa thành công.
        // Báo kết quả chưa xác định, không tự retry POST.
        emit(const ReservationCreateFailure(
          'Kết quả đặt trước chưa được xác định do mất kết nối. Vui lòng kiểm tra lại trong danh sách đặt trước.',
        ));
      } else {
        emit(ReservationCreateFailure(
          ReservationErrorMapper.mapError(e),
        ));
      }
    } finally {
      _isMutating = false;
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
