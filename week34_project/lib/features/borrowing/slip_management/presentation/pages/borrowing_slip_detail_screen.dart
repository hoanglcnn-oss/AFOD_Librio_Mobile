import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/app_toast.dart';
import '../../../../auth/bloc/auth_bloc.dart';
import '../../../../auth/bloc/auth_state.dart';
import '../../../../auth/data/models/app_role.dart';
import '../../../../members/data/api_members_repository.dart';
import '../../../../members/data/member_resolver.dart';
import '../../../../members/data/members_repository.dart';
import '../../../renewal/errors/renewal_error_mapper.dart';
import '../../../renewal/bloc/renew_slip_bloc.dart';
import '../../../renewal/bloc/renew_slip_event.dart';
import '../../../renewal/bloc/renew_slip_state.dart';
import '../../../renewal/presentation/widgets/slip_renewal_dialog.dart';
import '../../../renewal/presentation/widgets/slip_renewal_section.dart';
import '../../../shared/repositories/borrowing_slips_repository.dart';
import '../../../shared/models/borrowing_slip.dart';
import '../widgets/slip_detail_item_card.dart';
import '../widgets/slip_action_dialog.dart';
import '../widgets/slip_detail_actions.dart';
import '../widgets/slip_detail_header.dart';
import '../../../shared/widgets/borrowing_slip_ui_helper.dart';
import '../../../pending_slips/presentation/widgets/slip_decision_dialog.dart';
import '../../../return_slip/presentation/pages/borrowing_slip_return_screen.dart';
import '../../../pay_slip_fine/presentation/pages/pay_slip_fine_screen.dart';

class BorrowingSlipDetailScreen extends StatefulWidget {
  final String slipId;
  final BorrowingSlipsRepository repository;
  final RenewSlipBloc? renewSlipBloc;
  final MembersRepository? membersRepository;
  final MemberResolver? memberResolver;

  const BorrowingSlipDetailScreen({
    super.key,
    required this.slipId,
    required this.repository,
    this.renewSlipBloc,
    this.membersRepository,
    this.memberResolver,
  });

  @override
  State<BorrowingSlipDetailScreen> createState() =>
      _BorrowingSlipDetailScreenState();
}

class _BorrowingSlipDetailScreenState extends State<BorrowingSlipDetailScreen> {
  late Future<BorrowingSlip> _future;
  late final RenewSlipBloc _renewBloc;
  late final bool _isCustomBloc;
  late final MemberResolver _memberResolver;
  String? _resolvedMemberId;
  bool _isResolvingMember = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _isCustomBloc = widget.renewSlipBloc != null;
    _renewBloc =
        widget.renewSlipBloc ?? RenewSlipBloc(repository: widget.repository);
    _memberResolver =
        widget.memberResolver ??
        MemberResolver(
          membersRepository: widget.membersRepository ?? ApiMembersRepository(),
        );
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

      // 2. Dùng MemberResolver nếu chưa có liên kết (user.memberId == null)
      if (user.role.toUpperCase() == 'MEMBER') {
        _isResolvingMember = true;
        try {
          final resolved = await _memberResolver.resolve(
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
        return Scaffold(
          appBar: AppBar(title: const Text('Chi tiết phiếu mượn')),
          body: FutureBuilder<BorrowingSlip>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Không thể tải chi tiết phiếu'),
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('Thử lại'),
                      ),
                    ],
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
              final canUserRenew = canManageSlip || isOwner;
              final canCancelSlip =
                  isOwner &&
                  role == 'MEMBER' &&
                  slip.status.toUpperCase() == 'PENDING_APPROVAL';
              final isExcludedStatus = [
                'COMPLETED',
                'REJECTED',
                'CANCELLED',
              ].contains(slip.status.toUpperCase());

              return RefreshIndicator(
                onRefresh: () async {
                  _refresh();
                  await _future;
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    SlipDetailHeader(slip: slip, isOverdue: overdue),
                    if (!isExcludedStatus && canUserRenew) ...[
                      const SizedBox(height: 8),
                      SlipRenewalSection(
                        slip: slip,
                        renewState: renewState,
                        onRenewPressed: () => _openRenewDialog(context, slip),
                        onCheckEligibility: () {
                          _renewBloc.add(CheckSlipRenewalRequested(slip.id));
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Danh sách sách',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final item in slip.items)
                      BorrowingSlipItemCard(item: item, isOverdue: overdue),
                    const SizedBox(height: 16),
                    const Divider(),
                    Text(
                      'Tổng tiền phạt: '
                      '${BorrowingSlipUiHelper.formatMoney(slip.totalFine)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (slip.totalFine > 0)
                      Text(
                        slip.finePaid
                            ? 'Đã thanh toán tiền phạt'
                            : 'Chưa thanh toán tiền phạt',
                        style: TextStyle(
                          color: slip.finePaid
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    SlipDetailActions(
                      slip: slip,
                      canManageSlip: canManageSlip,
                      canCancelSlip: canCancelSlip,
                      isCancelling: _isCancelling,
                      onApprove: () => _processSlip(slip, approve: true),
                      onReject: () => _processSlip(slip, approve: false),
                      onCancel: () => _confirmCancelSlip(slip),
                      onReturn: () => _openReturn(slip),
                      onPayFine: () => _openPayFine(slip),
                      onRefresh: _refresh,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
