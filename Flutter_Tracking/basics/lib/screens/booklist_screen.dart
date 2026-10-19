import 'package:flutter/material.dart';
import '../widgets/book_card.dart';

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 1: Dựa vào constraints.maxWidth
          // để xác định isWide (ngưỡng 600px).
          final isWide = constraints.maxWidth >= 600;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 2: Nếu isWide == true
                if (isWide)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search books',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: searchBooks,
                        child: const Text('Search'),
                      ),
                    ],
                  )
                // 2D: Ngược lại, dùng Column
                // để xếp TextField và nút Search theo chiều dọc.
                else
                  Column(
                    children: [
                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search books',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Bấm nút để thực hiện tìm kiếm.
                      ElevatedButton(
                        onPressed: searchBooks,
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                // 3: Expanded chứa:
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
        },
      ),
    );
  }
}