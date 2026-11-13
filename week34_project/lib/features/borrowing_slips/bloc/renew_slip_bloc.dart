import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../renewal/errors/renewal_error_mapper.dart';
import '../data/borrowing_slips_repository.dart';
import '../data/models/borrowing_slip.dart';
import 'renew_slip_event.dart';
import 'renew_slip_state.dart';

class RenewSlipBloc extends Bloc<RenewSlipEvent, RenewSlipState> {
  final BorrowingSlipsRepository repository;
  bool _isSubmitting = false;

  RenewSlipBloc({required this.repository}) : super(const RenewSlipInitial()) {
    on<CheckSlipRenewalRequested>(_onCheckSlipRenewal);
    on<RenewSlipRequested>(_onRenewSlip);
  }

  Future<void> _onCheckSlipRenewal(
    CheckSlipRenewalRequested event,
    Emitter<RenewSlipState> emit,
  ) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    emit(const RenewSlipChecking());

    try {
      final slip = await repository.getBorrowingSlipById(slipId: event.slipId);
      emit(RenewSlipChecked(slip));
    } catch (error) {
      emit(RenewSlipFailure(getRenewalErrorMessage(error)));
    } finally {
      _isSubmitting = false;
    }
  }

  Future<void> _onRenewSlip(
    RenewSlipRequested event,
    Emitter<RenewSlipState> emit,
  ) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    emit(const RenewSlipSubmitting());

    // 1. Gọi getBorrowingSlipById(slipId) để lấy eligibility mới nhất từ Backend
    BorrowingSlip preSlip;
    try {
      preSlip = await repository.getBorrowingSlipById(slipId: event.slipId);
    } catch (error) {
      _isSubmitting = false;
      emit(RenewSlipFailure(getRenewalErrorMessage(error)));
      return;
    }

    // 2. Kiểm tra canRenew: chỉ gọi renewSlip khi canRenew == true
    if (preSlip.canRenew != true) {
      _isSubmitting = false;
      String message;
      if (preSlip.canRenew == false) {
        message =
            preSlip.renewalMessage ??
            mapRenewalReasonCode(preSlip.renewalReasonCode) ??
            'Phiếu mượn không đủ điều kiện để gia hạn.';
      } else {
        // canRenew == null: Chưa xác định điều kiện từ Backend
        message =
            preSlip.renewalMessage ??
            'Chưa xác định được điều kiện gia hạn từ hệ thống. Vui lòng kiểm tra lại sau.';
      }

      emit(RenewSlipFailure(message, latestSlip: preSlip));
      return;
    }

    // 3. canRenew == true: Tiến hành gọi renewSlip
    try {
      final renewedSlip = await repository.renewSlip(
        slipId: event.slipId,
        extraDays: event.extraDays,
      );

      BorrowingSlip finalSlip = renewedSlip;
      // Cập nhật từ Backend và GET lại chi tiết
      try {
        final refreshed = await repository.getBorrowingSlipById(
          slipId: event.slipId,
        );
        finalSlip = refreshed;
      } catch (_) {
        // GET refresh lỗi sau PATCH thành công không làm mất kết quả thành công
      }

      emit(RenewSlipSuccess(finalSlip));
    } on DioException catch (dioError) {
      final isTimeoutOrNetwork =
          dioError.type == DioExceptionType.connectionTimeout ||
          dioError.type == DioExceptionType.receiveTimeout ||
          dioError.type == DioExceptionType.sendTimeout ||
          dioError.type == DioExceptionType.connectionError;

      if (isTimeoutOrNetwork) {
        // Timeout/mất kết nối: GET kiểm tra renewCount, dueDate so với trước PATCH
        try {
          final reloaded = await repository.getBorrowingSlipById(
            slipId: event.slipId,
          );
          final didSucceed =
              reloaded.renewCount > preSlip.renewCount ||
              reloaded.dueDate.isAfter(preSlip.dueDate);

          if (didSucceed) {
            emit(RenewSlipSuccess(reloaded));
            return;
          }

          emit(
            RenewSlipFailure(
              'Không thể xác nhận kết quả gia hạn. Vui lòng kiểm tra lại phiếu trước khi thử lại.',
              latestSlip: reloaded,
            ),
          );
          return;
        } catch (_) {
          emit(
            const RenewSlipFailure(
              'Mất kết nối mạng và không thể xác nhận kết quả gia hạn. Vui lòng kiểm tra lại phiếu trước khi thử lại.',
            ),
          );
          return;
        }
      } else if (dioError.response?.statusCode == 409) {
        // HTTP 409: hiển thị lý do, GET lại eligibility
        BorrowingSlip? refreshed;
        try {
          refreshed = await repository.getBorrowingSlipById(
            slipId: event.slipId,
          );
        } catch (_) {}

        emit(
          RenewSlipFailure(
            getRenewalErrorMessage(dioError),
            latestSlip: refreshed,
          ),
        );
        return;
      }

      emit(
        RenewSlipFailure(getRenewalErrorMessage(dioError), latestSlip: preSlip),
      );
    } catch (error) {
      emit(RenewSlipFailure(getRenewalErrorMessage(error), latestSlip: preSlip));
    } finally {
      _isSubmitting = false;
    }
  }
}

