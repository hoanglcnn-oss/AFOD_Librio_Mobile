import 'package:flutter/material.dart';
import '../widgets/book_card.dart';
import 'bookform_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final TextEditingController searchController = TextEditingController();
  int characterCount = 0;

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
  List<Map<String, dynamic>> filterBooks(String keyword) {
    final normalizedKeyword = keyword.trim().toLowerCase();

    // Nếu normalizedKeyword rỗng:
    // Trả về toàn bộ books.
    if (normalizedKeyword.isEmpty) {
      return List.from(books); // Return full list if no keyword
    }
    // Nếu có từ khóa:
    // Dùng books.where(...) để lọc theo title.
    return books.where((book) {
      final title = book['title'] as String;
      return title.toLowerCase().contains(normalizedKeyword);
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    // E2:
    // Khởi tạo danh sách hiển thị ban đầu.
    filteredBooks = List.from(books);

    searchController.addListener(() {
      characterCount = searchController.text.length;
      setState(() {});
    });
  }

  // E3:
  // Viết hàm searchBooks().
  // Lấy keyword từ controller,
  // trim + toLowerCase,
  // lọc books theo title,
  // cập nhật UI bằng setState().
  void searchBooks() {
    setState(() {
      filteredBooks = filterBooks(searchController.text);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
        // 1: Tạo await Navigator.push
        final newBook = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => const BookFormScreen(),
          ),
        );
        if (!mounted) return;
        // 2. Nếu newBook != null thì thêm vào books 
        // và cập nhật filteredBooks trong setState().
        if (newBook != null) {
          setState(() {
            books.add(newBook);
            filteredBooks = filterBooks(searchController.text);
          });
        }
      },
        child: const Icon(Icons.add),
      ),
      // 1: Thêm thuộc tính title với giá trị 'Librio'.
      appBar: AppBar(title: const Text('Librio')),
      // 2: Tạo LayoutBuilder để xử lý giao diện trên các kích thước màn hình khác nhau.
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 1: Dựa vào constraints.maxWidth để xác định isWide (ngưỡng 600px).
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
                // Thông báo số ký tự
                Text('Số ký tự: $characterCount'),
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