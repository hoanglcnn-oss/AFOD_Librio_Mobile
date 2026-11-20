import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/repositories/books_repository.dart';
import 'books_detail_screen.dart';

String normalizeIsbn13(String input) {
  return input.replaceAll(RegExp(r'[\s-]'), '');
}

String? getIsbn13ValidationError(String input) {
  final isbn = normalizeIsbn13(input);

  if (!RegExp(r'^\d{13}$').hasMatch(isbn)) {
    return 'Vui lòng nhập ISBN-13 gồm 13 chữ số';
  }

  if (!isbn.startsWith('978') && !isbn.startsWith('979')) {
    return 'ISBN-13 phải bắt đầu bằng 978 hoặc 979';
  }

  var sum = 0;
  for (var index = 0; index < 12; index++) {
    final digit = int.parse(isbn[index]);
    sum += digit * (index.isEven ? 1 : 3);
  }

  final expectedCheckDigit = (10 - (sum % 10)) % 10;
  if (expectedCheckDigit != int.parse(isbn[12])) {
    return 'ISBN-13 không hợp lệ. Vui lòng kiểm tra lại mã';
  }

  return null;
}

class BarcodeScannerScreen extends StatefulWidget {
  final BooksRepository repository;

  const BarcodeScannerScreen({super.key, required this.repository});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
    formats: [BarcodeFormat.ean13],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  Future<void> _cameraOperation = Future<void>.value();
  bool _isAppActive = true;
  bool _isLookupInProgress = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startScanner());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppActive = true;
      if (!_isLookupInProgress) {
        unawaited(_startScanner());
      }
      return;
    }

    _isAppActive = false;
    unawaited(_stopScanner());
  }

  Future<void> _scheduleCameraOperation(Future<void> Function() operation) {
    final nextOperation = _cameraOperation.then((_) => operation());
    _cameraOperation = nextOperation.catchError((Object _) {});
    return nextOperation;
  }

  Future<void> _startScanner() {
    return _scheduleCameraOperation(() async {
      if (!mounted || !_isAppActive || _isLookupInProgress) {
        return;
      }

      final scannerState = _scannerController.value;
      if (scannerState.isRunning || scannerState.isStarting) {
        return;
      }

      await _scannerController.start();
    });
  }

  Future<void> _stopScanner() {
    return _scheduleCameraOperation(() async {
      final scannerState = _scannerController.value;
      if (!scannerState.isInitialized || !scannerState.isRunning) {
        return;
      }

      await _scannerController.stop();
    });
  }

  Future<void> _restartScanner() async {
    try {
      await _stopScanner();
      await _startScanner();
    } on MobileScannerException {
      _showCameraActionError();
    }
  }

  Future<void> _provideScanFeedback() async {
    try {
      await HapticFeedback.selectionClick();
    } on Exception {
      // Haptics are optional and must not block a valid ISBN lookup.
    }
  }

  Future<void> _findBook(String rawIsbn, {bool fromScanner = false}) async {
    if (!mounted || _isLookupInProgress) return;

    final isbn = normalizeIsbn13(rawIsbn);
    final validationError = getIsbn13ValidationError(isbn);

    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    _isLookupInProgress = true;
    _controller.value = TextEditingValue(
      text: isbn,
      selection: TextSelection.collapsed(offset: isbn.length),
    );
    setState(() => _error = null);

    try {
      if (fromScanner) {
        await _provideScanFeedback();
      }

      await _stopScanner();
      final book = await widget.repository.getBookByIsbn(isbn);

      if (!mounted) return;

      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) =>
              BookDetailScreen(bookId: book.id, repository: widget.repository),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.response?.statusCode == 404
            ? 'Không tìm thấy sách với ISBN này'
            : 'Không thể tra cứu sách. Vui lòng thử lại.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Đã xảy ra lỗi khi tra cứu sách';
      });
    } finally {
      _isLookupInProgress = false;
      if (mounted) {
        setState(() {});
        if (_isAppActive) {
          unawaited(_startScanner());
        }
      }
    }
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (!mounted || _isLookupInProgress) return;

    String? lastScannedValue;
    String? validationError;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null || rawValue.isEmpty) {
        continue;
      }

      final normalizedValue = normalizeIsbn13(rawValue);
      lastScannedValue = normalizedValue;
      validationError = getIsbn13ValidationError(normalizedValue);

      if (validationError == null) {
        await _findBook(normalizedValue, fromScanner: true);
        return;
      }
    }

    if (lastScannedValue != null && mounted) {
      _controller.value = TextEditingValue(
        text: lastScannedValue,
        selection: TextSelection.collapsed(offset: lastScannedValue.length),
      );
      setState(() => _error = validationError);
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
    } on MobileScannerException {
      _showCameraActionError();
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerController.switchCamera();
    } on MobileScannerException {
      _showCameraActionError();
    }
  }

  void _showCameraActionError() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Không thể điều khiển camera trên thiết bị này'),
      ),
    );
  }

  String _cameraErrorMessage(MobileScannerException error) {
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Quyền truy cập camera đã bị từ chối. '
            'Hãy cấp quyền camera trong Cài đặt hoặc nhập ISBN thủ công.',
      MobileScannerErrorCode.unsupported =>
        'Thiết bị không có camera phù hợp. Hãy nhập ISBN thủ công.',
      _ => 'Không mở được camera. Hãy thử lại hoặc nhập ISBN thủ công.',
    };
  }

  Widget _buildCameraError(BuildContext context, MobileScannerException error) {
    return ColoredBox(
      color: const Color(0xFF111827),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              _cameraErrorMessage(error),
              key: const Key('scanner_camera_error'),
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('scanner_retry_camera'),
              onPressed: _restartScanner,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại camera'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraControls() {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: _scannerController,
      builder: (context, scannerState, _) {
        final torchAvailable =
            scannerState.torchState != TorchState.unavailable;
        final cameraSwitchAvailable =
            scannerState.isRunning &&
            scannerState.cameraDirection != CameraFacing.unknown &&
            scannerState.cameraDirection != CameraFacing.external &&
            (scannerState.availableCameras == null ||
                scannerState.availableCameras! > 1);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              key: const Key('scanner_torch_button'),
              tooltip: 'Bật hoặc tắt đèn pin',
              onPressed:
                  scannerState.isRunning &&
                      torchAvailable &&
                      !_isLookupInProgress
                  ? _toggleTorch
                  : null,
              icon: Icon(
                scannerState.torchState == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
              ),
            ),
            const SizedBox(width: 16),
            IconButton.filledTonal(
              key: const Key('scanner_switch_camera_button'),
              tooltip: 'Đổi camera',
              onPressed: cameraSwitchAvailable && !_isLookupInProgress
                  ? _switchCamera
                  : null,
              icon: const Icon(Icons.cameraswitch_outlined),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isAppActive = false;
    _controller.dispose();
    unawaited(_cameraOperation.then((_) => _scannerController.dispose()));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tra cứu ISBN')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Icon(Icons.qr_code_scanner, size: 64),
            const SizedBox(height: 8),
            const Text(
              'Quét mã vạch ISBN-13',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          fit: BoxFit.cover,
                          onDetect: _onBarcodeDetected,
                          errorBuilder: _buildCameraError,
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 12,
                          child: _buildCameraControls(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('scanner_manual_isbn_field'),
              controller: _controller,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Nhập ISBN-13 thủ công',
                hintText: '978-... hoặc 979-...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _findBook,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                key: const Key('scanner_lookup_error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('scanner_find_book_button'),
              onPressed: _isLookupInProgress
                  ? null
                  : () => _findBook(_controller.text),
              child: _isLookupInProgress
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tìm sách'),
            ),
          ],
        ),
      ),
    );
  }
}
