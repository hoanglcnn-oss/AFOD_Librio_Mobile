import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/app_toast.dart';
import '../../../../auth/bloc/auth_bloc.dart';
import '../../../../auth/bloc/auth_state.dart';
import '../../../../auth/data/models/app_role.dart';
import '../../../../members/data/repositories/api_members_repository.dart';
import '../../../../members/data/repositories/members_repository.dart';
import '../../../renewal/errors/renewal_error_mapper.dart';
import '../../../renewal/bloc/renew_slip_bloc.dart';
import '../../../renewal/bloc/renew_slip_event.dart';
import '../../../renewal/bloc/renew_slip_state.dart';
import '../../../renewal/presentation/widgets/slip_renewal_dialog.dart';
import '../../../shared/repositories/borrowing_slips_repository.dart';
import '../../../shared/models/borrowing_slip.dart';
import '../widgets/slip_action_dialog.dart';
import '../widgets/slip_ticket_pass_card.dart';
import '../widgets/slip_summary_card.dart';
import '../widgets/slip_bottom_action_bar.dart';
import '../../../shared/widgets/borrowing_slip_ui_helper.dart';
import '../../../librarian_desk/presentation/widgets/slip_decision_dialog.dart';
import 'package:week34_project/features/borrowing/borrow_return/return/presentation/pages/borrowing_slip_return_screen.dart';
import 'package:week34_project/features/borrowing/borrow_return/return/presentation/pages/pay_slip_fine_screen.dart';

class BorrowingSlipDetailScreen extends StatefulWidget {
  final String slipId;
  final BorrowingSlipsRepository repository;
  final RenewSlipBloc? renewSlipBloc;
  final MembersRepository? membersRepository;

  const BorrowingSlipDetailScreen({
    super.key,
    required this.slipId,
    required this.repository,
    this.renewSlipBloc,
    this.membersRepository,
  });

  @override
  State<BorrowingSlipDetailScreen> createState() =>
      _BorrowingSlipDetailScreenState();
}

class _BorrowingSlipDetailScreenState extends State<BorrowingSlipDetailScreen> {
  late Future<BorrowingSlip> _future;
  late final RenewSlipBloc _renewBloc;
  late final bool _isCustomBloc;
  late final MembersRepository _membersRepository;
  String? _resolvedMemberId;
  bool _isResolvingMember = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _isCustomBloc = widget.renewSlipBloc != null;
    _renewBloc =
        widget.renewSlipBloc ?? RenewSlipBloc(repository: widget.repository);
    _membersRepository =
        widget.membersRepository ?? ApiMembersRepository();
    _load();
  }

  @override
  void didUpdateWidget(covariant BorrowingSlipDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slipId != widget.slipId) {
      _load();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveCurrentMemberId();
  }

  Future<void> _resolveCurrentMemberId() async {
    if (_isResolvingMember) return;
    AuthBloc? authBloc;
    try {
      authBloc = context.read<AuthBloc>();
    } catch (_) {}
    final authState = authBloc?.state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      // 1. Ưu tiên user.memberId nếu đã có
      if (user.memberId != null && user.memberId!.trim().isNotEmpty) {
        if (_resolvedMemberId != user.memberId!.trim()) {
          setState(() {
            _resolvedMemberId = user.memberId!.trim();
          });
        }
        return;
      }

      // 2. Tra cứu mã độc giả nếu chưa có liên kết (user.memberId == null)
      if (user.role.toUpperCase() == 'MEMBER') {
        _isResolvingMember = true;
        try {
          final resolved = await _membersRepository.resolveMemberId(
            memberId: user.memberId,
            email: user.email,
            role: user.role,
          );
          if (mounted && resolved != null) {
            setState(() {
              _resolvedMemberId = resolved;
            });
          }
        } catch (_) {
          // Bỏ qua lỗi tra cứu, giữ _resolvedMemberId = null (fail-closed)
        } finally {
          _isResolvingMember = false;
        }
      }
    }
  }

  @override
  void dispose() {
    if (!_isCustomBloc) {
      _renewBloc.close();
    }
    super.dispose();
  }

  void _load() {
    _future = widget.repository.getBorrowingSlipById(slipId: widget.slipId);
  }

  void _refresh() {
    setState(_load);
  }

  Future<void> _openReturn(BorrowingSlip slip) async {
    final returned = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BorrowingSlipReturnScreen(
          slip: slip,
          repository: widget.repository,
        ),
      ),
    );

    if (!mounted) return;

    // Luôn lấy lại dữ liệu Backend khi quay về,
    // kể cả khi user thoát mà chưa xác nhận.
    _refresh();

    if (returned == true) {
      AppToast.success(context, 'Đã ghi nhận trả sách thành công');
    }
  }

  Future<void> _openPayFine(BorrowingSlip slip) async {
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            PaySlipFineScreen(slip: slip, repository: widget.repository),
      ),
    );

    if (!mounted) return;

    // Không tin trạng thái cũ; gọi API lại để xác minh.
    _refresh();

    if (paid == true) {
      AppToast.success(context, 'Đã ghi nhận thanh toán tiền phạt');
    }
  }

  Future<void> _processSlip(BorrowingSlip slip, {required bool approve}) async {
    final shouldRefresh = approve
        ? await showApproveSlipDialog(
            context,
            slip: slip,
            repository: widget.repository,
          )
        : await showSlipDecisionDialog(
            context,
            slip: slip,
            repository: widget.repository,
            approve: false,
          );

    if (!mounted) return;

    if (shouldRefresh == true) {
      _refresh();
    }
  }

  Future<void> _confirmCancelSlip(BorrowingSlip slip) async {
    if (_isCancelling) return;

    final result = await showDialog<CancelSlipDialogResult>(
      context: context,
      builder: (_) => CancelSlipDialog(slip: slip),
    );

    if (result != null && mounted) {
      await _cancelSlip(slip, reason: result.reason);
    }
  }

  Future<void> _cancelSlip(BorrowingSlip slip, {String? reason}) async {
    if (_isCancelling) return;
    setState(() {
      _isCancelling = true;
    });

    try {
      final cancelledSlip = await widget.repository.cancelBorrowingSlip(
        slipId: slip.id,
        reason: reason,
      );
      if (!mounted) return;
      setState(() {
        _future = Future.value(cancelledSlip);
      });
      AppToast.success(context, 'Đã hủy phiếu mượn thành công');
    } catch (e) {
      if (!mounted) return;
      bool isTimeout = false;
      if (e is DioException) {
        isTimeout =
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;
      }

      if (isTimeout) {
        // Timeout/mất kết nối: không tự gửi PATCH lần 2; GET lại chi tiết để kiểm tra kết quả
        try {
          final verified = await widget.repository.getBorrowingSlipById(
            slipId: slip.id,
          );
          if (mounted) {
            if (verified.status.toUpperCase() == 'CANCELLED') {
              setState(() {
                _future = Future.value(verified);
              });
              AppToast.success(context, 'Đã hủy phiếu mượn thành công');
              return;
            } else {
              AppToast.warning(
                context,
                'Yêu cầu hủy phiếu chưa thể xác nhận do gián đoạn kết nối. Vui lòng kiểm tra lại trạng thái phiếu.',
              );
              setState(() {
                _future = Future.value(verified);
              });
              return;
            }
          }
        } catch (_) {
          if (mounted) {
            AppToast.warning(
              context,
              'Không thể xác minh kết quả hủy phiếu do kết nối mạng gián đoạn. Vui lòng thử lại sau.',
            );
          }
          return;
        }
      } else {
        String message = 'Không thể hủy phiếu mượn.';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            message = data['message'].toString();
          }
        }
        AppToast.error(context, message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  Future<void> _openRenewDialog(
    BuildContext context,
    BorrowingSlip slip,
  ) async {
    final extraDays = await showDialog<int>(
      context: context,
      builder: (_) => SlipRenewalDialog(slip: slip),
    );

    if (extraDays != null && context.mounted) {
      _renewBloc.add(
        RenewSlipRequested(slip.id, extraDays: extraDays, currentSlip: slip),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RenewSlipBloc, RenewSlipState>(
      bloc: _renewBloc,
      listenWhen: (previous, current) =>
          current is RenewSlipSuccess ||
          current is RenewSlipChecked ||
          current is RenewSlipFailure,
      listener: (context, state) {
        if (state is RenewSlipSuccess) {
          AppToast.success(context, state.message);
          // Giữ state.slip làm dữ liệu đã xác nhận
          setState(() {
            _future = Future.value(state.slip);
          });
          // Đồng bộ ngầm từ Backend; nếu mạng lỗi thì KHÔNG xóa mất kết quả thành công
          widget.repository
              .getBorrowingSlipById(slipId: widget.slipId)
              .then((refreshed) {
                if (mounted) {
                  setState(() {
                    _future = Future.value(refreshed);
                  });
                }
              })
              .catchError((_) {
                // Giữ nguyên state.slip đã xác nhận từ trước
              });
        } else if (state is RenewSlipChecked) {
          setState(() {
            _future = Future.value(state.slip);
          });
          if (state.slip.canRenew == true) {
            AppToast.success(context, 'Phiếu đủ điều kiện gia hạn.');
          } else if (state.slip.canRenew == false) {
            final reason =
                state.slip.renewalMessage ??
                mapRenewalReasonCode(state.slip.renewalReasonCode) ??
                'Phiếu không đủ điều kiện gia hạn.';
            AppToast.warning(context, reason);
          }
        } else if (state is RenewSlipFailure) {
          AppToast.error(context, state.message);
          if (state.latestSlip != null) {
            setState(() {
              _future = Future.value(state.latestSlip!);
            });
          }
        }
      },
      builder: (context, renewState) {
        return FutureBuilder<BorrowingSlip>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                appBar: AppBar(
                  title: const Text(
                    'Chi tiết phiếu mượn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1.0),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                body: const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                appBar: AppBar(
                  title: const Text(
                    'Chi tiết phiếu mượn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1.0),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Không thể tải chi tiết phiếu',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _refresh,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final slip = snapshot.data!;
            final overdue = BorrowingSlipUiHelper.isOverdue(slip);

            AuthBloc? authBloc;
            try {
              authBloc = context.read<AuthBloc>();
            } catch (_) {}

            final authState = authBloc?.state;
            final role = authState is AuthAuthenticated
                ? authState.user.role.toUpperCase()
                : '';

            final canManageSlip = AppRole.fromString(
              role,
            ).canManageBorrowingSlips;

            // Ưu tiên authState.user.memberId, sau đó dùng _resolvedMemberId từ MemberResolver
            // Fail-closed: Nếu không xác định được memberId thì isOwner = false
            final currentMemberId =
                (authState is AuthAuthenticated &&
                    authState.user.memberId != null &&
                    authState.user.memberId!.trim().isNotEmpty)
                ? authState.user.memberId!.trim()
                : _resolvedMemberId;

            final isOwner =
                currentMemberId != null && currentMemberId == slip.memberId;
            final isMember = role == 'MEMBER';
            final isExcludedStatus = [
              'COMPLETED',
              'REJECTED',
              'CANCELLED',
            ].contains(slip.status.toUpperCase());
            final canMemberRenew =
                isOwner &&
                isMember &&
                !isExcludedStatus &&
                (slip.status.toUpperCase() == 'BORROWED' ||
                    slip.status.toUpperCase() == 'PARTIAL_RETURNED');
            final canCancelSlip =
                isOwner &&
                role == 'MEMBER' &&
                slip.status.toUpperCase() == 'PENDING_APPROVAL';

            return LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 768;

                final actionBar = SlipBottomActionBar(
                  slip: slip,
                  canManageSlip: canManageSlip,
                  canCancelSlip: canCancelSlip,
                  isCancelling: _isCancelling,
                  canRenew: canMemberRenew,
                  renewState: renewState,
                  isCard: isTablet,
                  onApprove: () => _processSlip(slip, approve: true),
                  onReject: () => _processSlip(slip, approve: false),
                  onCancel: () => _confirmCancelSlip(slip),
                  onReturn: () => _openReturn(slip),
                  onPayFine: () => _openPayFine(slip),
                  onRenew: () => _openRenewDialog(context, slip),
                  onCheckEligibility: () {
                    _renewBloc.add(CheckSlipRenewalRequested(slip.id));
                  },
                  onRefresh: _refresh,
                );

                return Scaffold(
                  backgroundColor: const Color(0xFFF8FAFC),
                  appBar: AppBar(
                    title: const Text(
                      'Chi tiết phiếu mượn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    bottom: const PreferredSize(
                      preferredSize: Size.fromHeight(1.0),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFF0F172A)),
                        tooltip: 'Làm mới',
                        onPressed: _refresh,
                      ),
                    ],
                  ),
                  body: RefreshIndicator(
                    color: const Color(0xFF0D9488),
                    onRefresh: () async {
                      _refresh();
                      await _future;
                    },
                    child: isTablet
                        ? _buildTabletLayout(
                            context,
                            slip: slip,
                            overdue: overdue,
                            actionBar: actionBar,
                          )
                        : _buildMobileLayout(
                            context,
                            slip: slip,
                            overdue: overdue,
                          ),
                  ),
                  bottomNavigationBar: isTablet ? null : actionBar,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context, {
    required BorrowingSlip slip,
    required bool overdue,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        SlipTicketPassCard(slip: slip, isOverdue: overdue),
        const SizedBox(height: 16),
        SlipSummaryCard(slip: slip),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTabletLayout(
    BuildContext context, {
    required BorrowingSlip slip,
    required bool overdue,
    required SlipBottomActionBar actionBar,
  }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cột trái: Thẻ vé Ticket Pass
              Expanded(
                flex: 7,
                child: SlipTicketPassCard(slip: slip, isOverdue: overdue),
              ),
              const SizedBox(width: 16),
              // Cột phải: Bảng thao tác hành động (nếu có) + Tổng kết phiếu
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (actionBar.hasActions) ...[
                      actionBar,
                      const SizedBox(height: 16),
                    ],
                    SlipSummaryCard(slip: slip),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
