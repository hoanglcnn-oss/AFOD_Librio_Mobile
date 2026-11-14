import 'package:equatable/equatable.dart';

import '../models/return_slip_items_request.dart';

abstract class ReturnSlipEvent extends Equatable {
  const ReturnSlipEvent();

  @override
  List<Object?> get props => [];
}

class ReturnSlipRequested extends ReturnSlipEvent {
  final String slipId;
  final ReturnSlipItemsRequest request;

  const ReturnSlipRequested({required this.slipId, required this.request});

  @override
  List<Object?> get props => [slipId, request];
}
