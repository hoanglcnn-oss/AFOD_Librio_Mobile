import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: BookListScreen()));
}

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final TextEditingController searchController = TextEditingController();

  //mock data
  final List<Map<String, dynamic>> books = [
    {'title': 'Clean Code', 'author': 'Robert C. Martin', 'copies': 5},
    {'title': 'Doraemon', 'author': 'Fujiko Fujio', 'copies': 2},
    {'title': 'Sherlock Holmes', 'author': 'Arthur Conan Doyle', 'copies': 0},
  ];

  // E1:
  // Tạo biến filteredBooks để lưu danh sách sau lọc.
  // Dùng late vì sẽ gán giá trị ban đầu trong initState().
  late List<Map<String, dynamic>> filteredBooks;

  @override
  void initState() {
    super.initState();

    // E2:
    // Khởi tạo danh sách hiển thị ban đầu.
    filteredBooks = List.from(books);
  }

  // E3:
  // Viết hàm searchBooks().
  // Lấy keyword từ controller,
  // trim + toLowerCase,
  // lọc books theo title,
  // cập nhật UI bằng setState().
  void searchBooks() {
    setState(() {
      // Bỏ khoảng trắng đầu/cuối và chuyển về chữ thường
      // để tìm kiếm không phân biệt chữ hoa, chữ thường.
      String keyword = searchController.text.trim().toLowerCase();
      //ô search không có gì
      if (keyword.isEmpty) {
        filteredBooks = List.from(books);
      } else {
        //ô search có gì thì tìm sách theo title
        filteredBooks = books.where((book) {
          final title = book['title'] as String;
          return title.toLowerCase().contains(keyword);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Librio')),
      body: Column(
        children: [
          // E4:
          // TextField + nút Search.
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Search books',
              border: OutlineInputBorder(),
            ),
          ),
          // Bấm nút để thực hiện tìm kiếm.
          ElevatedButton(onPressed: searchBooks, child: Text('Search')),

          // E5:
          // Expanded chứa:
          // - Thông báo nếu filteredBooks rỗng.
          // - ListView.builder nếu có dữ liệu.
          // Mỗi item dùng BookCard
          // -> Chiếm phần chiều cao còn lại để hiển thị kết quả.
          Expanded(
            child: filteredBooks.isEmpty
                // Không có sách phù hợp thì hiển thị thông báo.
                ? Center(child: Text('No books found'))
                // có sách phù hợp thì hiển thị danh sách sách
                : ListView.builder(
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return BookCard(
                        title: book['title'],
                        author: book['author'],
                        copies: book['copies'],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

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
        trailing: Text('Copies: $copies'),
      ),
    );
  }
}
