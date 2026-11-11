import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/borrowing_repository.dart';
import 'return_slip_event.dart';
import 'return_slip_state.dart';

class ReturnSlipBloc extends Bloc<ReturnSlipEvent, ReturnSlipState> {
  final BorrowingRepository repository;

  bool _isSubmitting = false;

  ReturnSlipBloc({required this.repository})
    : super(const ReturnSlipInitial()) {
    on<ReturnSlipRequested>(_onReturn);
  }

  Future<void> _onReturn(
    ReturnSlipRequested event,
    Emitter<ReturnSlipState> emit,
  ) async {
    if (_isSubmitting || state is ReturnSlipSuccess) return;

    _isSubmitting = true;
    emit(const ReturnSlipSubmitting());

    try {
      final slip = await repository.returnSlipItems(
        slipId: event.slipId,
        request: event.request,
      );

      emit(ReturnSlipSuccess(slip));
    } on DioException catch (error) {
      final data = error.response?.data;
      final backendMessage = data is Map ? data['message'] : null;

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        emit(
          const ReturnSlipFailure(
            'Không xác nhận được kết quả trả sách. '
            'Hãy tải lại phiếu trước khi thử lại.',
          ),
        );
      } else {
        emit(
          ReturnSlipFailure(
            backendMessage is String
                ? backendMessage
                : 'Không thể trả sách. Vui lòng kiểm tra lại.',
          ),
        );
      }
    } catch (_) {
      emit(const ReturnSlipFailure('Không thể xử lý yêu cầu trả sách.'));
    } finally {
      _isSubmitting = false;
    }
  }
}
