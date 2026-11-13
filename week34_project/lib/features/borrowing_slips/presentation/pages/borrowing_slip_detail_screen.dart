import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/data/models/app_role.dart';
import '../../../members/data/api_members_repository.dart';
import '../../../members/data/member_resolver.dart';
import '../../../members/data/members_repository.dart';
import '../../../borrowing/renewal/errors/renewal_error_mapper.dart';
import '../../../borrowing/renewal/bloc/renew_slip_bloc.dart';
import '../../../borrowing/renewal/bloc/renew_slip_event.dart';
import '../../../borrowing/renewal/bloc/renew_slip_state.dart';
import '../../../borrowing/shared/repositories/borrowing_slips_repository.dart';
import '../../../borrowing/shared/models/borrowing_slip.dart';
import '../widgets/borrowing_slip_item_card.dart';
import '../widgets/borrowing_slip_ui_helper.dart';
import '../../../borrowing/approve_slip/presentation/widgets/slip_decision_dialog.dart';
import 'borrowing_slip_return_screen.dart';
import 'pay_slip_fine_screen.dart';

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

  Future<void> _confirmCancelSlip(BorrowingSlip slip) async {
    if (_isCancelling) return;
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hủy phiếu mượn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn hủy phiếu mượn ${slip.slipNumber}?'),
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
            key: const ValueKey('confirm_cancel_slip_button'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final reason = reasonController.text.trim();
      await _cancelSlip(
        slip,
        reason: reason.isNotEmpty ? reason : null,
      );
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
        isTimeout = e.type == DioExceptionType.connectionTimeout ||
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

  Future<void> _openRenewDialog(BuildContext context, BorrowingSlip slip) async {
    final extraDays = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        int selectedDays = 7;
        bool isCustom = false;
        final customController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isValid = false;
            if (!isCustom) {
              isValid = selectedDays >= 1 && selectedDays <= 14;
            } else {
              final parsed = int.tryParse(customController.text.trim());
              isValid = parsed != null && parsed >= 1 && parsed <= 14;
              if (isValid) {
                selectedDays = parsed;
              }
            }

            final currentDueDateStr =
                BorrowingSlipUiHelper.formatDate(slip.dueDate);
            final projectedDueDateStr = isValid
                ? BorrowingSlipUiHelper.formatDate(
                    slip.dueDate.add(Duration(days: selectedDays)),
                  )
                : '---';

            return AlertDialog(
              title: const Text('Gia hạn phiếu mượn'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gia hạn toàn bộ sách trong phiếu mượn này.'),
                    const SizedBox(height: 16),
                    const Text(
                      'Thời hạn gia hạn:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ChoiceChip(
                          key: const ValueKey('renew_chip_3'),
                          label: const Text('3 ngày'),
                          selected: !isCustom && selectedDays == 3,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                isCustom = false;
                                selectedDays = 3;
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          key: const ValueKey('renew_chip_7'),
                          label: const Text('7 ngày (mặc định)'),
                          selected: !isCustom && selectedDays == 7,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                isCustom = false;
                                selectedDays = 7;
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          key: const ValueKey('renew_chip_14'),
                          label: const Text('14 ngày (tối đa)'),
                          selected: !isCustom && selectedDays == 14,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                isCustom = false;
                                selectedDays = 14;
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          key: const ValueKey('renew_chip_custom'),
                          label: const Text('Số ngày khác'),
                          selected: isCustom,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                isCustom = true;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (isCustom) ...[
                      const SizedBox(height: 12),
                      TextField(
                        key: const ValueKey('renew_custom_input'),
                        controller: customController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Nhập số ngày (1–14)',
                          hintText: 'Ví dụ: 5',
                          border: const OutlineInputBorder(),
                          errorText: customController.text.isNotEmpty && !isValid
                              ? 'Số ngày phải từ 1 đến 14'
                              : null,
                        ),
                        onChanged: (_) {
                          setDialogState(() {});
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Hạn trả hiện tại:'),
                              Text(
                                currentDueDateStr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Hạn trả sau gia hạn:'),
                              Text(
                                projectedDueDateStr,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isValid
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Điều kiện gia hạn sẽ được hệ thống kiểm tra tự động.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  key: const ValueKey('confirm_renew_button'),
                  onPressed: isValid
                      ? () => Navigator.of(dialogContext).pop(selectedDays)
                      : null,
                  child: const Text('Xác nhận gia hạn'),
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
      final reason =
          slip.renewalMessage ??
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

              final canManageSlip =
                  AppRole.fromString(role).canManageBorrowingSlips;

              // Ưu tiên authState.user.memberId, sau đó dùng _resolvedMemberId từ MemberResolver
              // Fail-closed: Nếu không xác định được memberId thì isOwner = false
              final currentMemberId = (authState is AuthAuthenticated &&
                      authState.user.memberId != null &&
                      authState.user.memberId!.trim().isNotEmpty)
                  ? authState.user.memberId!.trim()
                  : _resolvedMemberId;

              final isOwner =
                  currentMemberId != null && currentMemberId == slip.memberId;
              final canUserRenew = canManageSlip || isOwner;
              final canCancelSlip = isOwner &&
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
                    if (canCancelSlip) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const ValueKey('cancel_pending_slip_button'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onPressed: _isCancelling
                              ? null
                              : () => _confirmCancelSlip(slip),
                          icon: _isCancelling
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cancel_outlined),
                          label: Text(
                            _isCancelling ? 'Đang hủy...' : 'Hủy phiếu mượn',
                          ),
                        ),
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
