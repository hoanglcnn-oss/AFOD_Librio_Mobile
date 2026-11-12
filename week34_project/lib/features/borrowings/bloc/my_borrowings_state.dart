import 'package:equatable/equatable.dart';

import '../data/models/paginated_borrowings.dart';

abstract class MyBorrowingsState extends Equatable {
  const MyBorrowingsState();

  @override
  List<Object?> get props => [];
}

//BLoC vừa được tạo	-> Chưa tải dữ liệu
class MyBorrowingsInitial extends MyBorrowingsState {
  const MyBorrowingsInitial();
}

//Đang gọi Repository	-> Vòng tròn loading
class MyBorrowingsLoading extends MyBorrowingsState {
  const MyBorrowingsLoading();
}

//API trả về thành công ->	Danh sách phiếu mượn
class MyBorrowingsLoaded extends MyBorrowingsState {
  final PaginatedBorrowings borrowingsPage;

  const MyBorrowingsLoaded(this.borrowingsPage);

  @override
  List<Object?> get props => [borrowingsPage];
}

//API lỗi, thiếu JWT hoặc parse lỗi ->	Thông báo lỗi + nút thử lại
class MyBorrowingsFailure extends MyBorrowingsState {
  final String message;

  const MyBorrowingsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class MyBorrowingsReturning extends MyBorrowingsState {
  final BorrowingsPage borrowingsPage;
  final String borrowingId;

  const MyBorrowingsReturning({
    required this.borrowingsPage,
    required this.borrowingId,
  });

  @override
  List<Object?> get props => [borrowingsPage, borrowingId];
}

class MyBorrowingsReturnSuccess extends MyBorrowingsState {
  final BorrowingsPage borrowingsPage;

  const MyBorrowingsReturnSuccess(this.borrowingsPage);

  @override
  List<Object?> get props => [borrowingsPage];
}

class MyBorrowingsReturnFailure extends MyBorrowingsState {
  final BorrowingsPage borrowingsPage;
  final String message;

  const MyBorrowingsReturnFailure({
    required this.borrowingsPage,
    required this.message,
  });

  @override
  List<Object?> get props => [borrowingsPage, message];
}

class MyBorrowingsRenewing extends MyBorrowingsState {
  final BorrowingsPage borrowingsPage;
  final String borrowingId;

  const MyBorrowingsRenewing({
    required this.borrowingsPage,
    required this.borrowingId,
  });

  @override
  List<Object?> get props => [borrowingsPage, borrowingId];
}

class MyBorrowingsRenewSuccess extends MyBorrowingsState {
  final BorrowingsPage borrowingsPage;

  const MyBorrowingsRenewSuccess(this.borrowingsPage);

  @override
  List<Object?> get props => [borrowingsPage];
}

class MyBorrowingsRenewFailure extends MyBorrowingsState {
  final BorrowingsPage borrowingsPage;
  final String message;

  const MyBorrowingsRenewFailure({
    required this.borrowingsPage,
    required this.message,
  });

  @override
  List<Object?> get props => [borrowingsPage, message];
}
