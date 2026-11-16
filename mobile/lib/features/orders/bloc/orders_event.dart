import 'package:equatable/equatable.dart';

/// Base event class for order management.
abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers initial order history load.
class OrdersStarted extends OrdersEvent {
  const OrdersStarted();
}

/// Triggers manual pull-to-refresh of orders.
class OrdersRefreshed extends OrdersEvent {
  const OrdersRefreshed();
}

/// Filters order history by status (e.g. All, Active, Pending, Paid, Shipped, Delivered, Cancelled).
class OrderStatusFilterSelected extends OrdersEvent {
  final String? status;

  const OrderStatusFilterSelected(this.status);

  @override
  List<Object?> get props => [status];
}
