import 'package:equatable/equatable.dart';

import '../data/models/create_slip_request.dart';

abstract class CreateSlipEvent extends Equatable {
  const CreateSlipEvent();

  @override
  List<Object?> get props => [];
}

class CreateSlipRequested extends CreateSlipEvent {
  final CreateSlipRequest request;

  const CreateSlipRequested(this.request);

  @override
  List<Object?> get props => [request];
}
