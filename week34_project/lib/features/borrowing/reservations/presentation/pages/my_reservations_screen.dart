import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/app_toast.dart';
import '../../../../auth/bloc/auth_bloc.dart';
import '../../../../auth/bloc/auth_state.dart';
import '../../../../books/data/books_repository.dart';
import '../../../../books/data/models/book.dart';
import '../../../shared/repositories/borrowing_slips_repository.dart';
import '../../../create_slip/presentation/pages/borrow_confirm_screen.dart';
import '../../../../members/data/api_members_repository.dart';
import '../../../../members/data/member_resolver.dart';
import '../../../../members/data/members_repository.dart';
import '../../bloc/reservations_bloc.dart';
import '../../bloc/reservations_event.dart';
import '../../bloc/reservations_state.dart';
import '../../data/api_reservations_repository.dart';
import '../../data/models/reservation.dart';
import '../../data/reservations_repository.dart';
import '../widgets/reservation_card.dart';
import '../widgets/cancel_reservation_dialog.dart';

class MyReservationsScreen extends StatelessWidget {
  final String? memberId;
  final ReservationsRepository? repository;
  final MemberResolver? memberResolver;
  final BooksRepository? booksRepository;
  final BorrowingSlipsRepository? borrowingSlipsRepository;
  final MembersRepository? membersRepository;

  const MyReservationsScreen({
    super.key,
    this.memberId,
    this.repository,
    this.memberResolver,
    this.booksRepository,
    this.borrowingSlipsRepository,
    this.membersRepository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReservationsBloc(
        reservationsRepository: repository ?? ApiReservationsRepository(),
      ),
      child: _MyReservationsView(
        memberId: memberId,
        memberResolver: memberResolver,
        booksRepository: booksRepository,
        borrowingSlipsRepository: borrowingSlipsRepository,
        membersRepository: membersRepository,
      ),
    );
  }
}

class _MyReservationsView extends StatefulWidget {
  final String? memberId;
  final MemberResolver? memberResolver;
  final BooksRepository? booksRepository;
  final BorrowingSlipsRepository? borrowingSlipsRepository;
  final MembersRepository? membersRepository;

  const _MyReservationsView({
    this.memberId,
    this.memberResolver,
    this.booksRepository,
    this.borrowingSlipsRepository,
    this.membersRepository,
  });

  @override
  State<_MyReservationsView> createState() => _MyReservationsViewState();
}

class _MyReservationsViewState extends State<_MyReservationsView> {
  int _page = 1;
  String? _authenticatedMemberId;
  String? _displayMemberId;
  bool _isResolvingMember = true;
  String? _resolveError;

  @override
  void initState() {
    super.initState();
    _initMember();
  }

  Future<void> _initMember() async {
    setState(() {
      _isResolvingMember = true;
      _resolveError = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        setState(() {
          _isResolvingMember = false;
          _resolveError = 'Vui lòng đăng nhập để xem danh sách đặt trước.';
        });
        return;
      }

      final user = authState.user;
      final resolver = widget.memberResolver ??
          MemberResolver(membersRepository: ApiMembersRepository());

      // Luôn xác thực và lấy memberId từ user đã đăng nhập
      _authenticatedMemberId = await resolver.resolve(
        memberId: user.memberId,
        email: user.email,
        role: user.role,
      );

      // Nếu widget.memberId được truyền vào: chỉ dùng làm target filter nếu hợp lệ,
      // nhưng TUYỆT ĐỐI KHÔNG dùng làm bằng chứng ownership!
      _displayMemberId =
          (widget.memberId != null && widget.memberId!.trim().isNotEmpty)
              ? widget.memberId!.trim()
              : _authenticatedMemberId;

      if (!mounted) return;

      if (_displayMemberId == null || _displayMemberId!.isEmpty) {
        setState(() {
          _isResolvingMember = false;
          _resolveError = 'Không tìm thấy hồ sơ độc giả.';
        });
        return;
      }

      setState(() {
        _isResolvingMember = false;
      });

      _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResolvingMember = false;
        _resolveError = 'Không thể xác định thông tin độc giả.';
      });
    }
  }

  void _loadData() {
    if (_displayMemberId == null) return;
    context.read<ReservationsBloc>().add(
          LoadReservations(
            memberId: _displayMemberId!,
            page: _page,
          ),
        );
  }

  Future<void> _onRefresh() async {
    if (_displayMemberId == null) return;
    final completer = Completer<void>();
    context.read<ReservationsBloc>().add(
          RefreshReservations(
            _displayMemberId!,
            completer: completer,
          ),
        );
    await completer.future;
  }

  void _changePage(int newPage) {
    if (_displayMemberId == null) return;
    setState(() {
      _page = newPage;
    });
    context.read<ReservationsBloc>().add(
          LoadReservations(
            memberId: _displayMemberId!,
            page: newPage,
          ),
        );
  }

  Future<void> _showCancelDialog(Reservation reservation) async {
    // Không tin tưởng memberId từ UI làm bằng chứng ownership:
    // Chỉ cho phép hủy nếu reservation thuộc về tài khoản đang đăng nhập
    if (_authenticatedMemberId == null ||
        _authenticatedMemberId != reservation.memberId) {
      AppToast.error(
        context,
        'Bạn không có quyền hủy phiếu đặt trước của người khác.',
      );
      return;
    }

    final result = await showDialog<CancelReservationDialogResult>(
      context: context,
      builder: (_) => CancelReservationDialog(
        reservation: reservation,
      ),
    );

    if (result != null && mounted && _authenticatedMemberId != null) {
      context.read<ReservationsBloc>().add(
            CancelReservationRequested(
              reservationId: reservation.id,
              memberId: _authenticatedMemberId!,
              reason: result.reason,
            ),
          );
    }
  }

  Future<void> _handleCreateSlip(Reservation reservation) async {
    Book? book;
    if (widget.booksRepository != null) {
      try {
        book = await widget.booksRepository!.getBookById(reservation.bookId);
      } catch (_) {}
    }

    book ??= Book(
      id: reservation.bookId,
      title: reservation.bookTitle,
      authorName: 'Đang cập nhật',
      isbn: '',
      categoryName: '',
      description: '',
      coverUrl: null,
      copiesTotal: 1,
      copiesAvailable: 1,
      status: 'AVAILABLE',
    );

    if (!mounted) return;

    AuthBloc? authBloc;
    try {
      authBloc = context.read<AuthBloc>();
    } catch (_) {}

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          final screen = BorrowConfirmScreen(
            book: book!,
            borrowingSlipsRepository: widget.borrowingSlipsRepository,
            membersRepository: widget.membersRepository,
          );
          if (authBloc != null) {
            return BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: screen,
            );
          }
          return screen;
        },
      ),
    );

    if (!mounted) return;
    _onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt trước của tôi'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isResolvingMember) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_resolveError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_resolveError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initMember,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return BlocConsumer<ReservationsBloc, ReservationsState>(
      listener: (context, state) {
        if (state is ReservationCancelSuccess) {
          AppToast.success(context, state.message);
        } else if (state is ReservationCancelFailure) {
          AppToast.error(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is ReservationsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ReservationsFailure) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        final paginated = switch (state) {
          ReservationsLoaded(:final paginated) => paginated,
          ReservationCancelling(:final paginated) => paginated,
          ReservationCancelSuccess(:final paginated) => paginated,
          ReservationCancelFailure(:final paginated) => paginated,
          _ => null,
        };

        if (paginated == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final reservations = paginated.items;

        if (reservations.isEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Bạn chưa có yêu cầu đặt trước nào',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final cancellingId =
            state is ReservationCancelling ? state.reservationId : null;

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final item = reservations[index];
                    // Không tin memberId từ UI, chỉ so với _authenticatedMemberId
                    final isOwner = _authenticatedMemberId != null &&
                        _authenticatedMemberId!.isNotEmpty &&
                        item.memberId == _authenticatedMemberId;

                    return ReservationCard(
                      reservation: item,
                      isOwner: isOwner,
                      isCancelling: cancellingId == item.id,
                      onCancel: () => _showCancelDialog(item),
                      onCreateSlip:
                          item.isReady ? () => _handleCreateSlip(item) : null,
                    );
                  },
                ),
              ),
              if (paginated.totalPages > 1) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Trang trước',
                        onPressed:
                            _page <= 1 ? null : () => _changePage(_page - 1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('Trang $_page/${paginated.totalPages}'),
                      IconButton(
                        tooltip: 'Trang tiếp',
                        onPressed: paginated.hasNextPage
                            ? () => _changePage(_page + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
