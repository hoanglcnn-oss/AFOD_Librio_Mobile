import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:week34_project/features/books/data/models/book.dart';
import 'package:week34_project/features/books/data/models/paginated_books.dart';
import 'package:week34_project/features/books/data/repositories/books_repository.dart';
import 'package:week34_project/features/books/presentation/pages/barcode_scanner_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ISBN-13 validation', () {
    test('normalizes spaces and hyphens before validating', () {
      expect(normalizeIsbn13(' 978-0-13-235088-4 '), '9780132350884');
      expect(getIsbn13ValidationError(' 978-0-13-235088-4 '), isNull);
      expect(getIsbn13ValidationError('9791234567896'), isNull);
    });

    test('rejects invalid length, prefix, and checksum', () {
      expect(getIsbn13ValidationError('978013235088'), isNotNull);
      expect(getIsbn13ValidationError('9770132350884'), contains('978'));
      expect(
        getIsbn13ValidationError('9780132350885'),
        contains('không hợp lệ'),
      );
    });
  });

  group('BarcodeScannerScreen', () {
    late MobileScannerPlatform originalPlatform;

    setUp(() {
      originalPlatform = MobileScannerPlatform.instance;
      MobileScannerController.resetPlatformSessionOwner();
    });

    tearDown(() {
      MobileScannerPlatform.instance = originalPlatform;
      MobileScannerController.resetPlatformSessionOwner();
    });

    testWidgets(
      'accepts one lookup per scan and allows rescanning after navigation',
      (tester) async {
        final platform = _FakeMobileScannerPlatform();
        final repository = _ControlledBooksRepository();
        MobileScannerPlatform.instance = platform;

        var hapticCount = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'HapticFeedback.vibrate' &&
                  call.arguments == 'HapticFeedbackType.selectionClick') {
                hapticCount++;
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        await tester.pumpWidget(
          MaterialApp(home: BarcodeScannerScreen(repository: repository)),
        );
        await tester.pumpAndSettle();

        const capture = BarcodeCapture(
          barcodes: [Barcode(rawValue: '9780132350884')],
        );
        platform.addBarcode(capture);
        platform.addBarcode(capture);
        await tester.pump();

        expect(repository.isbnLookupCalls, 1);
        expect(repository.lastIsbn, '9780132350884');
        expect(hapticCount, 1);

        repository.completeLookup();
        await tester.pumpAndSettle();

        expect(find.text('Chi tiết sách'), findsOneWidget);
        expect(platform.stopCalls, greaterThanOrEqualTo(1));

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(platform.startCalls, greaterThanOrEqualTo(2));

        repository.prepareLookup();
        platform.addBarcode(capture);
        await tester.pump();

        expect(repository.isbnLookupCalls, 2);
        expect(hapticCount, 2);

        repository.completeLookup();
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'invalid scanned and manual ISBN values never call repository',
      (tester) async {
        final platform = _FakeMobileScannerPlatform();
        final repository = _ControlledBooksRepository();
        MobileScannerPlatform.instance = platform;

        await tester.pumpWidget(
          MaterialApp(home: BarcodeScannerScreen(repository: repository)),
        );
        await tester.pumpAndSettle();

        platform.addBarcode(
          const BarcodeCapture(barcodes: [Barcode(rawValue: '9780132350885')]),
        );
        await tester.pumpAndSettle();

        expect(repository.isbnLookupCalls, 0);
        expect(find.textContaining('ISBN-13 không hợp lệ'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('scanner_manual_isbn_field')),
          '9770132350884',
        );
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();

        expect(repository.isbnLookupCalls, 0);
        expect(
          find.textContaining('bắt đầu bằng 978 hoặc 979'),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets('pauses and resumes camera with app lifecycle', (tester) async {
      final platform = _FakeMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;

      await tester.pumpWidget(
        MaterialApp(
          home: BarcodeScannerScreen(repository: _ControlledBooksRepository()),
        ),
      );
      await tester.pumpAndSettle();
      expect(platform.startCalls, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(platform.stopCalls, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(platform.startCalls, 2);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('camera controls are disabled when hardware is unavailable', (
      tester,
    ) async {
      final platform = _FakeMobileScannerPlatform(
        availableCameras: 1,
        torchState: TorchState.unavailable,
      );
      MobileScannerPlatform.instance = platform;

      await tester.pumpWidget(
        MaterialApp(
          home: BarcodeScannerScreen(repository: _ControlledBooksRepository()),
        ),
      );
      await tester.pumpAndSettle();

      final torchButton = tester.widget<IconButton>(
        find.byKey(const Key('scanner_torch_button')),
      );
      final switchButton = tester.widget<IconButton>(
        find.byKey(const Key('scanner_switch_camera_button')),
      );
      expect(torchButton.onPressed, isNull);
      expect(switchButton.onPressed, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('camera controls use torch and switch supported cameras', (
      tester,
    ) async {
      final platform = _FakeMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;

      await tester.pumpWidget(
        MaterialApp(
          home: BarcodeScannerScreen(repository: _ControlledBooksRepository()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('scanner_torch_button')));
      await tester.pumpAndSettle();
      expect(platform.toggleTorchCalls, 1);

      await tester.tap(find.byKey(const Key('scanner_switch_camera_button')));
      await tester.pumpAndSettle();
      expect(platform.startDirections, [CameraFacing.back, CameraFacing.front]);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('camera errors keep manual ISBN fallback available', (
      tester,
    ) async {
      final platform = _FakeMobileScannerPlatform(
        startError: const MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        ),
      );
      MobileScannerPlatform.instance = platform;

      await tester.pumpWidget(
        MaterialApp(
          home: BarcodeScannerScreen(repository: _ControlledBooksRepository()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scanner_camera_error')), findsOneWidget);
      expect(find.textContaining('Quyền truy cập camera'), findsOneWidget);
      expect(find.byKey(const Key('scanner_retry_camera')), findsOneWidget);
      expect(
        find.byKey(const Key('scanner_manual_isbn_field')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });
}

class _FakeMobileScannerPlatform extends MobileScannerPlatform {
  _FakeMobileScannerPlatform({
    this.availableCameras = 2,
    this.torchState = TorchState.off,
    this.startError,
  });

  final int availableCameras;
  final TorchState torchState;
  final MobileScannerException? startError;
  final StreamController<BarcodeCapture> _barcodeController =
      StreamController<BarcodeCapture>.broadcast();
  final StreamController<TorchState> _torchController =
      StreamController<TorchState>.broadcast();

  int startCalls = 0;
  int stopCalls = 0;
  int toggleTorchCalls = 0;
  final List<CameraFacing> startDirections = [];

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodeController.stream;

  @override
  Stream<TorchState> get torchStateStream => _torchController.stream;

  @override
  Stream<double> get zoomScaleStateStream => Stream.value(1);

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    startCalls++;
    startDirections.add(startOptions.cameraDirection);
    if (startError != null) {
      throw startError!;
    }

    return MobileScannerViewAttributes(
      cameraDirection: startOptions.cameraDirection,
      currentTorchMode: torchState,
      size: const Size(320, 320),
      numberOfCameras: availableCameras,
    );
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> toggleTorch() async {
    toggleTorchCalls++;
    _torchController.add(TorchState.on);
  }

  @override
  Widget buildCameraView() {
    return const ColoredBox(color: Colors.black);
  }

  void addBarcode(BarcodeCapture capture) {
    _barcodeController.add(capture);
  }

  @override
  Future<void> dispose() async {
    await _barcodeController.close();
    await _torchController.close();
  }
}

class _ControlledBooksRepository implements BooksRepository {
  static const book = Book(
    id: 'book-01',
    isbn: '9780132350884',
    title: 'Clean Code',
    authorName: 'Robert C. Martin',
    categoryName: 'Programming',
    description: 'A book about writing clean code.',
    coverUrl: null,
    status: 'AVAILABLE',
    copiesAvailable: 3,
    copiesTotal: 5,
  );

  Completer<Book> _lookupCompleter = Completer<Book>();
  int isbnLookupCalls = 0;
  String? lastIsbn;

  void prepareLookup() {
    _lookupCompleter = Completer<Book>();
  }

  void completeLookup() {
    _lookupCompleter.complete(book);
  }

  @override
  Future<Book> getBookByIsbn(String isbn) {
    isbnLookupCalls++;
    lastIsbn = isbn;
    return _lookupCompleter.future;
  }

  @override
  Future<Book> getBookById(String id) async => book;

  @override
  Future<PaginatedBooks> getBooks({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    return const PaginatedBooks(
      page: 1,
      totalPages: 1,
      hasNextPage: false,
      books: [book],
    );
  }
}
