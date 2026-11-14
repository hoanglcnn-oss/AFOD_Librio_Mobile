import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/books/bloc/books_bloc.dart';
import 'package:week34_project/features/books/bloc/books_event.dart';
import 'package:week34_project/features/books/bloc/books_state.dart';
import 'package:week34_project/features/books/data/books_repository.dart';
import 'package:week34_project/features/books/data/models/book.dart';
import 'package:week34_project/features/books/data/models/paginated_books.dart';
import 'package:week34_project/features/books/presentation/pages/books_screen.dart';
import 'package:week34_project/features/books/presentation/widgets/book_card.dart';
import 'package:week34_project/features/books/presentation/widgets/book_search_bar.dart';

class ConfigurableBooksRepository implements BooksRepository {
  final Future<PaginatedBooks> Function({int page, int limit, String? search})?
  onGetBooks;

  ConfigurableBooksRepository({this.onGetBooks});

  @override
  Future<PaginatedBooks> getBooks({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    if (onGetBooks != null) {
      return onGetBooks!(page: page, limit: limit, search: search);
    }
    return const PaginatedBooks(
      page: 1,
      totalPages: 1,
      hasNextPage: false,
      books: [],
    );
  }

  @override
  Future<Book> getBookById(String id) async => throw UnimplementedError();

  @override
  Future<Book> getBookByIsbn(String isbn) async => throw UnimplementedError();
}

void main() {
  const sampleBook1 = Book(
    id: 'book-01',
    isbn: '9780132350884',
    title: 'Clean Code',
    authorName: 'Robert C. Martin',
    categoryName: 'Programming',
    description: 'Clean code handbook.',
    coverUrl: null,
    status: 'AVAILABLE',
    copiesAvailable: 3,
    copiesTotal: 5,
  );

  const sampleBook2 = Book(
    id: 'book-02',
    isbn: '9780201633610',
    title: 'Design Patterns',
    authorName: 'Erich Gamma et al.',
    categoryName: 'Software Engineering',
    description: 'Elements of Reusable Object-Oriented Software.',
    coverUrl: null,
    status: 'AVAILABLE',
    copiesAvailable: 2,
    copiesTotal: 4,
  );

  void setLargeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget createSubject({
    required BooksBloc bloc,
    required BooksRepository repository,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: bloc,
          child: BooksScreen(repository: repository),
        ),
      ),
    );
  }

  group('BooksScreen Top Section UI & Interactions', () {
    testWidgets(
      'Hiển thị AppBar chuẩn: Tiêu đề "Danh sách sách", nút "Chọn nhiều", thanh tìm kiếm và số lượng kết quả',
      (tester) async {
        setLargeScreen(tester);

        final repo = ConfigurableBooksRepository();
        final bloc = BooksBloc(booksRepository: repo);
        addTearDown(bloc.close);

        bloc.emit(
          const BooksLoaded(
            paginatedBooks: PaginatedBooks(
              page: 1,
              totalPages: 1,
              hasNextPage: false,
              books: [sampleBook1, sampleBook2],
            ),
          ),
        );

        await tester.pumpWidget(createSubject(bloc: bloc, repository: repo));
        await tester.pump();

        // 1. Tiêu đề App bar
        expect(find.text('Danh sách sách'), findsOneWidget);

        // 2. Nút Chọn nhiều với checklist icon
        expect(find.text('Chọn nhiều'), findsOneWidget);
        expect(find.byIcon(Icons.checklist), findsOneWidget);

        // 3. Search Bar
        expect(find.byType(BookSearchBar), findsOneWidget);
        expect(find.text('Tìm theo tên sách, tác giả...'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.clear), findsOneWidget);
        expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);

        // 4. Số lượng kết quả
        final resultCountWidget = tester.widget<Text>(
          find.byKey(const Key('books_result_count')),
        );
        expect(resultCountWidget.textSpan?.toPlainText(), 'Hiển thị 2 sách');

        // 5. Chuyển sang chế độ chọn nhiều
        await tester.tap(find.text('Chọn nhiều'));
        await tester.pump();

        expect(find.text('Đã chọn 0 đầu sách'), findsOneWidget);
        expect(find.text('Hủy'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      },
    );

    testWidgets('Xóa tìm kiếm (Clear search) làm sạch input', (tester) async {
      setLargeScreen(tester);

      final repo = ConfigurableBooksRepository();
      final bloc = BooksBloc(booksRepository: repo);
      addTearDown(bloc.close);

      bloc.emit(
        const BooksLoaded(
          paginatedBooks: PaginatedBooks(
            page: 1,
            totalPages: 1,
            hasNextPage: false,
            books: [sampleBook1],
          ),
        ),
      );

      await tester.pumpWidget(createSubject(bloc: bloc, repository: repo));
      await tester.pump();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'Flutter');
      await tester.pump();
      expect(find.text('Flutter'), findsOneWidget);

      final clearBtn = find.byTooltip('Xóa tìm kiếm');
      await tester.tap(clearBtn);
      await tester.pump();

      expect(find.text('Flutter'), findsNothing);
    });
  });

  group('BooksScreen Bottom Section Pagination States', () {
    testWidgets(
      'End of list: Khi hasNextPage == false -> hiển thị "Đã hiển thị tất cả sách"',
      (tester) async {
        setLargeScreen(tester);

        final repo = ConfigurableBooksRepository();
        final bloc = BooksBloc(booksRepository: repo);
        addTearDown(bloc.close);

        bloc.emit(
          const BooksLoaded(
            paginatedBooks: PaginatedBooks(
              page: 1,
              totalPages: 1,
              hasNextPage: false,
              books: [sampleBook1],
            ),
          ),
        );

        await tester.pumpWidget(createSubject(bloc: bloc, repository: repo));
        await tester.pump();

        expect(find.text('Đã hiển thị tất cả sách'), findsOneWidget);
        expect(find.text('Đang tải thêm...'), findsNothing);
        expect(find.text('Không thể tải thêm sách.'), findsNothing);
      },
    );

    testWidgets(
      'Loading: Khi isLoadingMore == true -> hiển thị "Đang tải thêm..." và progress indicator',
      (tester) async {
        setLargeScreen(tester);

        final repo = ConfigurableBooksRepository();
        final bloc = BooksBloc(booksRepository: repo);
        addTearDown(bloc.close);

        bloc.emit(
          const BooksLoaded(
            paginatedBooks: PaginatedBooks(
              page: 1,
              totalPages: 2,
              hasNextPage: true,
              books: [sampleBook1],
            ),
            isLoadingMore: true,
          ),
        );

        await tester.pumpWidget(createSubject(bloc: bloc, repository: repo));
        await tester.pump();

        expect(find.text('Đang tải thêm...'), findsOneWidget);
        expect(find.text('Đã hiển thị tất cả sách'), findsNothing);
        expect(find.text('Không thể tải thêm sách.'), findsNothing);
      },
    );

    testWidgets(
      'Error: Khi paginationError != null -> hiển thị thông báo lỗi và nút "Thử lại"',
      (tester) async {
        setLargeScreen(tester);

        final repo = ConfigurableBooksRepository();
        final bloc = BooksBloc(booksRepository: repo);
        addTearDown(bloc.close);

        bloc.emit(
          const BooksLoaded(
            paginatedBooks: PaginatedBooks(
              page: 1,
              totalPages: 2,
              hasNextPage: true,
              books: [sampleBook1],
            ),
            paginationError: 'Không thể tải thêm sách.',
          ),
        );

        await tester.pumpWidget(createSubject(bloc: bloc, repository: repo));
        await tester.pump();

        expect(find.text('Không thể tải thêm sách.'), findsOneWidget);
        expect(find.text('Thử lại'), findsOneWidget);
        expect(find.text('Đang tải thêm...'), findsNothing);
        expect(find.text('Đã hiển thị tất cả sách'), findsNothing);
      },
    );
  });

  group('BookCard Preservation', () {
    testWidgets('Màu nền BookCard khi không chọn là Color(0xFFF7FAFD)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BookCard(book: sampleBook1)),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, const Color(0xFFF7FAFD));
      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('Robert C. Martin'), findsOneWidget);
      expect(find.text('Còn 3 cuốn'), findsOneWidget);
    });
  });

  group('BooksBloc Pagination Events', () {
    test('LoadMoreBooks nối thêm sách và cập nhật trang', () async {
      int requestedPage = 0;
      final repo = ConfigurableBooksRepository(
        onGetBooks: ({int page = 1, int limit = 10, String? search}) async {
          requestedPage = page;
          if (page == 1) {
            return const PaginatedBooks(
              page: 1,
              totalPages: 2,
              hasNextPage: true,
              books: [sampleBook1],
            );
          } else {
            return const PaginatedBooks(
              page: 2,
              totalPages: 2,
              hasNextPage: false,
              books: [sampleBook2],
            );
          }
        },
      );

      final bloc = BooksBloc(booksRepository: repo);
      final firstLoaded = bloc.stream.firstWhere((s) => s is BooksLoaded);
      bloc.add(const LoadBooks());
      await firstLoaded;

      expect(requestedPage, 1);
      expect((bloc.state as BooksLoaded).paginatedBooks.books.length, 1);

      final secondLoaded = bloc.stream.firstWhere(
        (s) => s is BooksLoaded && s.paginatedBooks.books.length == 2,
      );
      bloc.add(const LoadMoreBooks());
      await secondLoaded;

      expect(requestedPage, 2);
      final loaded = bloc.state as BooksLoaded;
      expect(loaded.paginatedBooks.books.length, 2);
      expect(loaded.paginatedBooks.hasNextPage, false);
      expect(loaded.isLoadingMore, false);

      await bloc.close();
    });

    test(
      'LoadMoreBooks khi gặp lỗi emit paginationError mà không mất sách đã có',
      () async {
        final repo = ConfigurableBooksRepository(
          onGetBooks: ({int page = 1, int limit = 10, String? search}) async {
            if (page == 1) {
              return const PaginatedBooks(
                page: 1,
                totalPages: 2,
                hasNextPage: true,
                books: [sampleBook1],
              );
            }
            throw Exception('Lỗi mạng khi tải trang 2');
          },
        );

        final bloc = BooksBloc(booksRepository: repo);
        final firstLoaded = bloc.stream.firstWhere((s) => s is BooksLoaded);
        bloc.add(const LoadBooks());
        await firstLoaded;

        final errorLoaded = bloc.stream.firstWhere(
          (s) => s is BooksLoaded && s.paginationError != null,
        );
        bloc.add(const LoadMoreBooks());
        await errorLoaded;

        final state = bloc.state as BooksLoaded;
        expect(state.paginatedBooks.books.length, 1);
        expect(state.isLoadingMore, false);
        expect(state.paginationError, 'Không thể tải thêm sách.');

        await bloc.close();
      },
    );
  });
}
