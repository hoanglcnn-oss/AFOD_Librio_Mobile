import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/data/models/app_role.dart';
import '../../../renewal/errors/renewal_error_mapper.dart';
import '../../bloc/renew_slip_bloc.dart';
import '../../bloc/renew_slip_event.dart';
import '../../bloc/renew_slip_state.dart';
import '../../data/borrowing_slips_repository.dart';
import '../../data/models/borrowing_slip.dart';
import '../widgets/borrowing_slip_item_card.dart';
import '../widgets/borrowing_slip_ui_helper.dart';
import '../widgets/slip_decision_dialog.dart';
import 'borrowing_slip_return_screen.dart';
import 'pay_slip_fine_screen.dart';

class BorrowingSlipDetailScreen extends StatefulWidget {
  final String slipId;
  final BorrowingSlipsRepository repository;
  final RenewSlipBloc? renewSlipBloc;

  const BorrowingSlipDetailScreen({
    super.key,
    required this.slipId,
    required this.repository,
    this.renewSlipBloc,
  });

  @override
  State<BorrowingSlipDetailScreen> createState() =>
      _BorrowingSlipDetailScreenState();
}

class _BorrowingSlipDetailScreenState extends State<BorrowingSlipDetailScreen> {
  late Future<BorrowingSlip> _future;
  late final RenewSlipBloc _renewBloc;
  late final bool _isCustomBloc;

  @override
  void initState() {
    super.initState();
    _isCustomBloc = widget.renewSlipBloc != null;
    _renewBloc =
        widget.renewSlipBloc ?? RenewSlipBloc(repository: widget.repository);
    _load();
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
    final shouldRefresh = await showSlipDecisionDialog(
      context,
      slip: slip,
      repository: widget.repository,
      approve: approve,
    );

    if (!mounted) return;

    if (shouldRefresh == true) {
      _refresh();
    }
  }

  Future<void> _openRenewDialog(BuildContext context, BorrowingSlip slip) async {
    int selectedDays = 7;
    final extraDays = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Gia hạn phiếu mượn'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gia hạn toàn bộ sách trong phiếu mượn này.'),
                  const SizedBox(height: 16),
                  const Text('Chọn số ngày muốn gia hạn:'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: selectedDays,
                    items: [
                      for (int day = 1; day <= 14; day++)
                        DropdownMenuItem(
                          value: day,
                          child: Text('$day ngày'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedDays = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Điều kiện gia hạn sẽ được hệ thống kiểm tra tự động.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(selectedDays),
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );

    if (extraDays != null && context.mounted) {
      _renewBloc.add(
        RenewSlipRequested(
          slip.id,
          extraDays: extraDays,
          currentSlip: slip,
        ),
      );
    }
  }

  Widget _buildRenewalSection(
    BuildContext context,
    BorrowingSlip slip,
    RenewSlipState renewState,
  ) {
    final isProcessing =
        renewState is RenewSlipSubmitting || renewState is RenewSlipChecking;

    if (isProcessing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              renewState is RenewSlipChecking
                  ? 'Đang kiểm tra điều kiện gia hạn...'
                  : 'Đang xử lý gia hạn...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    if (slip.canRenew == true) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: () => _openRenewDialog(context, slip),
          icon: const Icon(Icons.update, size: 18),
          label: const Text('Gia hạn'),
        ),
      );
    }

    if (slip.canRenew == false) {
      final reason = slip.renewalMessage ??
          mapRenewalReasonCode(slip.renewalReasonCode) ??
          'Phiếu mượn không đủ điều kiện để gia hạn.';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.update, size: 18),
              label: const Text('Gia hạn'),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reason,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    // canRenew == null: nút Kiểm tra gia hạn, không tự cho phép PATCH
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () {
              _renewBloc.add(CheckSlipRenewalRequested(slip.id));
            },
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Kiểm tra gia hạn'),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Chưa có thông tin gia hạn. Bấm để kiểm tra điều kiện.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
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
          setState(() {
            _future = Future.value(state.slip);
          });
          _refresh();
        } else if (state is RenewSlipChecked) {
          setState(() {
            _future = Future.value(state.slip);
          });
          if (state.slip.canRenew == true) {
            AppToast.success(context, 'Phiếu đủ điều kiện gia hạn.');
          } else if (state.slip.canRenew == false) {
            final reason = state.slip.renewalMessage ??
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

              final canManageSlip =
                  AppRole.fromString(role).canManageBorrowingSlips;
              final currentUserId =
                  authState is AuthAuthenticated ? authState.user.id : null;
              final isOwner =
                  currentUserId == null || currentUserId == slip.memberId;
              final canUserRenew = canManageSlip || isOwner;
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
                    Text(
                      slip.slipNumber,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Độc giả: ${slip.memberName != null && slip.memberName!.trim().isNotEmpty ? slip.memberName!.trim() : (slip.memberCardNumber != null && slip.memberCardNumber!.trim().isNotEmpty ? slip.memberCardNumber!.trim() : slip.memberId)}',
                              ),
                              if (slip.memberName != null &&
                                  slip.memberName!.trim().isNotEmpty &&
                                  slip.memberCardNumber != null &&
                                  slip.memberCardNumber!.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Số thẻ: ${slip.memberCardNumber!.trim()}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 2),
                              Text(
                                'Mã độc giả: ${slip.memberId}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Sao chép mã độc giả',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: slip.memberId),
                            );
                            AppToast.success(context, 'Đã sao chép mã độc giả');
                          },
                        ),
                      ],
                    ),
                    Text(
                      'Trạng thái: '
                      '${BorrowingSlipUiHelper.slipStatus(slip.status)}',
                    ),
                    Text(
                      'Hạn trả: '
                      '${BorrowingSlipUiHelper.formatDate(slip.dueDate)}',
                    ),
                    Text('Số lần đã gia hạn: ${slip.renewCount}'),
                    if (!isExcludedStatus && canUserRenew) ...[
                      const SizedBox(height: 8),
                      _buildRenewalSection(context, slip, renewState),
                    ],
                    if (overdue) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Phiếu có sách chưa trả và đã quá hạn',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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
                    if (BorrowingSlipUiHelper.hasUnpaidFine(slip)) ...[
                      const SizedBox(height: 12),
                      if (canManageSlip)
                        FilledButton.icon(
                          onPressed: () => _openPayFine(slip),
                          icon: const Icon(Icons.payments_outlined),
                          label: const Text('Ghi nhận đã thu tiền phạt'),
                        )
                      else
                        const Text(
                          'Vui lòng liên hệ thủ thư để thanh toán tiền phạt.',
                        ),
                    ],
                    if (canManageSlip && slip.status == 'PENDING_APPROVAL') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _processSlip(slip, approve: false),
                              child: const Text('Từ chối'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _processSlip(slip, approve: true),
                              icon: const Icon(Icons.check),
                              label: const Text('Duyệt phiếu'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (canManageSlip &&
                        (slip.status == 'BORROWED' ||
                            slip.status == 'PARTIAL_RETURNED') &&
                        slip.items.any((item) => item.remainingQuantity > 0)) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _openReturn(slip),
                        icon: const Icon(Icons.assignment_return),
                        label: const Text('Xác nhận trả sách'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Cập nhật trạng thái phiếu'),
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
