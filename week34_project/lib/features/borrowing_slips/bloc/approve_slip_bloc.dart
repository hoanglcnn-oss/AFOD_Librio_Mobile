import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../borrowing/shared/repositories/borrowing_slips_repository.dart';
import 'approve_slip_event.dart';
import 'approve_slip_state.dart';

class ApproveSlipBloc extends Bloc<ApproveSlipEvent, ApproveSlipState> {
  final BorrowingSlipsRepository repository;

  bool _isSubmitting = false;

  ApproveSlipBloc({required this.repository})
    : super(const ApproveSlipInitial()) {
    on<ApproveSlipEvent>(_onProcessSlip);
  }

  Future<void> _onProcessSlip(
    ApproveSlipEvent event,
    Emitter<ApproveSlipState> emit,
  ) async {
    // Chặn nhấn Duyệt/Từ chối đồng thời.
    if (_isSubmitting || state is ApproveSlipSuccess) {
      return;
    }

    _isSubmitting = true;
    emit(const ApproveSlipSubmitting());

    try {
      if (event is ApproveSlipRequested) {
        final slip = await repository.approveBorrowingSlip(
          slipId: event.slipId,
        );

        if (slip.status != 'BORROWED') {
          emit(
            const ApproveSlipFailure(
              'Trạng thái phiếu sau khi duyệt không hợp lệ. '
              'Vui lòng tải lại phiếu.',
              requiresRefresh: true,
            ),
          );
          return;
        }

        emit(ApproveSlipSuccess(slip));
      } else if (event is RejectSlipRequested) {
        if (event.reason.trim().isEmpty) {
          emit(const ApproveSlipFailure('Cần nhập lý do từ chối phiếu.'));
          return;
        }

        final slip = await repository.rejectBorrowingSlip(
          slipId: event.slipId,
          reason: event.reason.trim(),
        );

        if (slip.status != 'REJECTED') {
          emit(
            const ApproveSlipFailure(
              'Trạng thái phiếu sau khi từ chối không hợp lệ. '
              'Vui lòng tải lại phiếu.',
              requiresRefresh: true,
            ),
          );
          return;
        }

        emit(ApproveSlipSuccess(slip));
      }
    } on BorrowLimitExceededException catch (e) {
      emit(
        ApproveSlipLimitExceeded(
          message: e.message,
          code: e.code,
          details: e.details,
        ),
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      if (data is Map) {
        final code = data['code']?.toString() ?? data['errorCode']?.toString();
        final message = data['message']?.toString() ?? '';
        if (code == 'BORROW_LIMIT_EXCEEDED' ||
            message.contains('BORROW_LIMIT_EXCEEDED') ||
            message.toLowerCase().contains('vượt quá hạn mức') ||
            message.toLowerCase().contains('vượt hạn mức')) {
          emit(
            ApproveSlipLimitExceeded(
              message: message.isNotEmpty
                  ? message
                  : 'Độc giả đã vượt quá hạn mức mượn sách.',
              code: code,
              details: data['details'] is Map
                  ? Map<String, dynamic>.from(data['details'] as Map)
                  : null,
            ),
          );
          return;
        }
      }

      String? backendMessage;

      if (data is Map) {
        final message = data['message'];

        if (message is String && message.trim().isNotEmpty) {
          backendMessage = message;
        } else if (message is List) {
          backendMessage = message.whereType<String>().join('\n');
          if (backendMessage.isEmpty) backendMessage = null;
        }
      }

      final connectionUncertain =
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError;

      if (connectionUncertain) {
        emit(
          const ApproveSlipFailure(
            'Chưa xác nhận được kết quả xử lý phiếu. '
            'Vui lòng tải lại trạng thái trước khi thử lại.',
            requiresRefresh: true,
          ),
        );
      } else if (statusCode == 409) {
        emit(
          ApproveSlipFailure(
            backendMessage ?? 'Phiếu vừa được xử lý hoặc tồn kho đã thay đổi.',
            requiresRefresh: true,
          ),
        );
      } else {
        emit(
          ApproveSlipFailure(
            backendMessage ??
                'Không thể xử lý phiếu mượn. '
                    'Vui lòng kiểm tra lại.',
            requiresRefresh: statusCode == 404,
          ),
        );
      }
    } catch (_) {
      emit(
        const ApproveSlipFailure(
          'Không thể xử lý yêu cầu. '
          'Vui lòng kiểm tra lại trạng thái phiếu.',
          requiresRefresh: true,
        ),
      );
    } finally {
      _isSubmitting = false;
    }
  }
}
