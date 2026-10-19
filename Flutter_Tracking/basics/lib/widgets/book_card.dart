import 'package:flutter/material.dart';

// Widget hiển thị thông tin của một cuốn sách.
// Dùng StatelessWidget vì widget này chỉ nhận dữ liệu
// và hiển thị, không tự quản lý state.
class BookCard extends StatelessWidget {
  final String title;
  final String author;
  final int copies;

  const BookCard({
    super.key,
    required this.title,
    required this.author,
    required this.copies,
  });

  @override
  Widget build(BuildContext context) {
    // E6:
    // Trả về UI hiển thị thông tin một cuốn sách.
    // Có thể dùng Row, Column, Padding, Icon...
    return Card(
      // ListTile hiển thị tiêu đề sách, tác giả sách, số bản còn lại
      child: ListTile(
        title: Text(title),
        subtitle: Text(author),
        // Hiển thị số bản còn lại
        trailing: Text(
          // Nếu copies == 0 -> hiển thị 'Hết sách'
          // Ngược lại -> hiển thị 'Còn ... bản'
          // dùng toán tử ba ngôi condition ? A : B
          copies == 0 ? 'Hết sách' : 'Còn $copies bản',
          // thuộc tính style
          style: TextStyle(color: copies == 0 ? Colors.red : Colors.green),
        ),
      ),
    );
  }
}