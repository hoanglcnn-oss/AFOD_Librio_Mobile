import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../renewal/errors/renewal_error_mapper.dart';
import '../data/borrowing_repository.dart';
import '../data/models/borrowing.dart';
import '../data/models/paginated_borrowings.dart';
import 'my_borrowings_event.dart';
import 'my_borrowings_state.dart';

class MyBorrowingsBloc extends Bloc<MyBorrowingsEvent, MyBorrowingsState> {
  final BorrowingRepository borrowingRepository;
  bool _isRenewing = false;

  MyBorrowingsBloc({required this.borrowingRepository})
    : super(const MyBorrowingsInitial()) {
    on<LoadMyBorrowings>(_onLoadMyBorrowings);
    on<ReturnBookRequested>(_onReturnBookRequested);
    on<RenewBorrowingRequested>(_onRenewBorrowingRequested);
  }

  Future<void> _onLoadMyBorrowings(
    LoadMyBorrowings event,
    Emitter<MyBorrowingsState> emit,
  ) async {
    emit(const MyBorrowingsLoading());

    try {
      final result = await borrowingRepository.getBorrowings(
        memberId: event.memberId,
      );

      emit(MyBorrowingsLoaded(result));
    } catch (error) {
      emit(MyBorrowingsFailure(error.toString()));
    }
  }

  Future<void> _onReturnBookRequested(
    ReturnBookRequested event,
    Emitter<MyBorrowingsState> emit,
  ) async {
    final currentState = state;

    final page = switch (currentState) {
      MyBorrowingsLoaded s => s.borrowingsPage,
      MyBorrowingsReturnFailure s => s.borrowingsPage,
      MyBorrowingsRenewFailure s => s.borrowingsPage,
      MyBorrowingsReturnSuccess s => s.borrowingsPage,
      MyBorrowingsRenewSuccess s => s.borrowingsPage,
      _ => null,
    };

    if (page == null) {
      return;
    }
    // Không cho phép trả lại phiếu đã RETURNED.
    final matches = page.borrowings.where(
      (borrowing) => borrowing.id == event.borrowingId,
    );

    if (matches.isEmpty || matches.first.status == 'RETURNED') {
      return;
    }

    emit(
      MyBorrowingsReturning(
        borrowingsPage: page,
        borrowingId: event.borrowingId,
      ),
    );

    try {
      await borrowingRepository.returnBook(borrowingId: event.borrowingId);

      emit(MyBorrowingsReturnSuccess(page));
    } catch (error) {
      emit(
        MyBorrowingsReturnFailure(
          borrowingsPage: page,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _onRenewBorrowingRequested(
    RenewBorrowingRequested event,
    Emitter<MyBorrowingsState> emit,
  ) async {
    // Chặn request gia hạn trùng khi đang xử lý (concurrency guard)
    if (_isRenewing) return;

    final currentState = state;

    final page = switch (currentState) {
      MyBorrowingsLoaded s => s.borrowingsPage,
      MyBorrowingsRenewFailure s => s.borrowingsPage,
      MyBorrowingsReturnFailure s => s.borrowingsPage,
      MyBorrowingsRenewSuccess s => s.borrowingsPage,
      MyBorrowingsReturnSuccess s => s.borrowingsPage,
      _ => null,
    };

    if (page == null) return;

    // Tìm phiếu mượn tương ứng trong danh sách
    final matches = page.borrowings.where(
      (borrowing) => borrowing.id == event.borrowingId,
    );

    if (matches.isEmpty) return;

    _isRenewing = true;
    emit(
      MyBorrowingsRenewing(
        borrowingsPage: page,
        borrowingId: event.borrowingId,
      ),
    );

    try {
      // 1. Trước khi gia hạn, gọi getBorrowingById() để lấy eligibility mới nhất từ Backend
      final detail = await borrowingRepository.getBorrowingById(
        event.borrowingId,
      );

      // 2. canRenew != true: không gửi POST renewLoan.
      // Phân biệt null = chưa xác định, false = bị từ chối.
      if (detail.canRenew != true) {
        final String message;
        if (detail.canRenew == false) {
          final reason =
              detail.renewalMessage ??
              mapRenewalReasonCode(detail.renewalReasonCode);
          message = (reason != null && reason.isNotEmpty)
              ? reason
              : 'Phiếu mượn không đủ điều kiện gia hạn';
        } else {
          // canRenew == null: Chưa xác định được điều kiện gia hạn từ Backend
          message =
              detail.renewalMessage ??
              'Chưa xác định được điều kiện gia hạn từ hệ thống. Vui lòng thử lại sau.';
        }

        emit(
          MyBorrowingsRenewFailure(
            borrowingsPage: _updateBorrowingInPage(page, detail),
            message: message,
          ),
        );
        return;
      }

      // 3. canRenew == true: gọi renewLoan() với extraDays (mặc định 7)
      final renewedBorrowing = await borrowingRepository.renewLoan(
        borrowingId: event.borrowingId,
        extraDays: event.extraDays,
      );

      final updatedPage = _updateBorrowingInPage(page, renewedBorrowing);
      emit(MyBorrowingsRenewSuccess(updatedPage));
    } on DioException catch (dioError) {
      PaginatedBorrowings latestPage = page;

      final isTimeoutOrNetwork =
          dioError.type == DioExceptionType.connectionTimeout ||
          dioError.type == DioExceptionType.receiveTimeout ||
          dioError.type == DioExceptionType.sendTimeout ||
          dioError.type == DioExceptionType.connectionError;

      if (isTimeoutOrNetwork) {
        // POST có thể đã thành công trên Backend trước khi kết nối bị ngắt.
        // Cần GET lại chi tiết sau timeout để kiểm tra dueDate, renewCount.
        try {
          final reloaded = await borrowingRepository.getBorrowingById(
            event.borrowingId,
          );
          final oldBorrowing = matches.first;
          final didSucceedOnBackend =
              reloaded.renewCount > oldBorrowing.renewCount ||
              reloaded.dueDate.isAfter(oldBorrowing.dueDate);

          if (didSucceedOnBackend) {
            emit(
              MyBorrowingsRenewSuccess(_updateBorrowingInPage(page, reloaded)),
            );
            return;
          }
          latestPage = _updateBorrowingInPage(page, reloaded);
        } catch (_) {
          // Nếu GET lại cũng timeout thì giữ nguyên page
        }
      } else if (dioError.response?.statusCode == 409) {
        try {
          final reloaded = await borrowingRepository.getBorrowingById(
            event.borrowingId,
          );
          latestPage = _updateBorrowingInPage(page, reloaded);
        } catch (_) {}
      }

      emit(
        MyBorrowingsRenewFailure(
          borrowingsPage: latestPage,
          message: getRenewalErrorMessage(dioError),
        ),
      );
    } catch (error) {
      // Lỗi ngoại lệ: không tự cộng ngày, không retry tự động
      emit(
        MyBorrowingsRenewFailure(
          borrowingsPage: page,
          message: getRenewalErrorMessage(error),
        ),
      );
    } finally {
      _isRenewing = false;
    }
  }

  PaginatedBorrowings _updateBorrowingInPage(
    PaginatedBorrowings page,
    Borrowing updatedBorrowing,
  ) {
    final updatedList = page.borrowings.map((b) {
      if (b.id == updatedBorrowing.id) {
        return updatedBorrowing;
      }
      return b;
    }).toList();

    return PaginatedBorrowings(
      borrowings: updatedList,
      page: page.page,
      limit: page.limit,
      totalItems: page.totalItems,
      totalPages: page.totalPages,
      hasNextPage: page.hasNextPage,
    );
  }
}
