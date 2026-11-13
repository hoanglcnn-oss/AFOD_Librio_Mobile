import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../members/data/api_members_repository.dart';
import '../../../members/data/member_resolver.dart';
import '../../bloc/reservations_bloc.dart';
import '../../bloc/reservations_event.dart';
import '../../bloc/reservations_state.dart';
import '../../data/api_reservations_repository.dart';
import '../../data/models/reservation.dart';
import '../../data/reservations_repository.dart';
import '../widgets/reservation_card.dart';

class MyReservationsScreen extends StatelessWidget {
  final String? memberId;
  final ReservationsRepository? repository;
  final MemberResolver? memberResolver;

  const MyReservationsScreen({
    super.key,
    this.memberId,
    this.repository,
    this.memberResolver,
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
      ),
    );
  }
}

class _MyReservationsView extends StatefulWidget {
  final String? memberId;
  final MemberResolver? memberResolver;

  const _MyReservationsView({
    this.memberId,
    this.memberResolver,
  });

  @override
  State<_MyReservationsView> createState() => _MyReservationsViewState();
}

class _MyReservationsViewState extends State<_MyReservationsView> {
  int _page = 1;
  String? _resolvedMemberId;
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
      if (widget.memberId != null && widget.memberId!.trim().isNotEmpty) {
        _resolvedMemberId = widget.memberId!.trim();
      } else {
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

        _resolvedMemberId = await resolver.resolve(
          memberId: user.memberId,
          email: user.email,
          role: user.role,
        );
      }

      if (!mounted) return;

      if (_resolvedMemberId == null || _resolvedMemberId!.isEmpty) {
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
    if (_resolvedMemberId == null) return;
    context.read<ReservationsBloc>().add(
          LoadReservations(
            memberId: _resolvedMemberId!,
            page: _page,
          ),
        );
  }

  Future<void> _onRefresh() async {
    if (_resolvedMemberId == null) return;
    context.read<ReservationsBloc>().add(
          RefreshReservations(_resolvedMemberId!),
        );
  }

  void _changePage(int newPage) {
    if (_resolvedMemberId == null) return;
    setState(() {
      _page = newPage;
    });
    context.read<ReservationsBloc>().add(
          LoadReservations(
            memberId: _resolvedMemberId!,
            page: newPage,
          ),
        );
  }

  Future<void> _showCancelDialog(Reservation reservation) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hủy đặt trước'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn hủy đặt trước cuốn sách "${reservation.bookTitle}"?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy (tùy chọn)',
                border: OutlineInputBorder(),
                hintText: 'Nhập lý do hủy...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Đóng'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && _resolvedMemberId != null) {
      context.read<ReservationsBloc>().add(
            CancelReservationRequested(
              reservationId: reservation.id,
              memberId: _resolvedMemberId!,
              reason: reasonController.text.trim().isNotEmpty
                  ? reasonController.text.trim()
                  : null,
            ),
          );
    }
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
                    final isOwner = _resolvedMemberId != null &&
                        item.memberId == _resolvedMemberId;

                    return ReservationCard(
                      reservation: item,
                      isOwner: isOwner,
                      isCancelling: cancellingId == item.id,
                      onCancel: () => _showCancelDialog(item),
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
