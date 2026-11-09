import 'package:equatable/equatable.dart';

import '../data/models/borrowings_page.dart';

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
  final BorrowingsPage borrowingsPage;

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
