import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/borrowing_repository.dart';
import 'pay_slip_fine_event.dart';
import 'pay_slip_fine_state.dart';

class PaySlipFineBloc extends Bloc<PaySlipFineEvent, PaySlipFineState> {
  final BorrowingRepository repository;
  bool _isSubmitting = false;

  PaySlipFineBloc({required this.repository})
    : super(const PaySlipFineInitial()) {
    on<PaySlipFineRequested>(_onPay);
  }

  Future<void> _onPay(
    PaySlipFineRequested event,
    Emitter<PaySlipFineState> emit,
  ) async {
    if (_isSubmitting || state is PaySlipFineSuccess) return;

    _isSubmitting = true;
    emit(const PaySlipFineSubmitting());

    try {
      final slip = await repository.paySlipFine(slipId: event.slipId);
      emit(PaySlipFineSuccess(slip));
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map ? data['message'] : null;

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        emit(
          const PaySlipFineFailure(
            'Chưa xác nhận được kết quả ghi nhận thanh toán. '
            'Vui lòng tải lại phiếu trước khi thử lại.',
          ),
        );
      } else {
        emit(
          PaySlipFineFailure(
            message is String
                ? message
                : 'Không thể ghi nhận thanh toán tiền phạt.',
          ),
        );
      }
    } catch (_) {
      emit(
        const PaySlipFineFailure(
          'Không thể xử lý yêu cầu thanh toán tiền phạt.',
        ),
      );
    } finally {
      _isSubmitting = false;
    }
  }
}
