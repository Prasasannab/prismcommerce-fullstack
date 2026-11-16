import 'package:equatable/equatable.dart';
import '../../checkout/data/models/order_response_model.dart';

/// Base state class for order management.
abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

/// Initial state before orders have been requested.
class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

/// Loading state while order history is being retrieved.
class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

/// Loaded state containing both full list and currently active status filter.
class OrdersLoaded extends OrdersState {
  final List<OrderResponseModel> orders;
  final List<OrderResponseModel> filteredOrders;
  final String? selectedStatus;

  const OrdersLoaded({
    required this.orders,
    required this.filteredOrders,
    this.selectedStatus,
  });

  OrdersLoaded copyWith({
    List<OrderResponseModel>? orders,
    List<OrderResponseModel>? filteredOrders,
    String? selectedStatus,
    bool clearFilter = false,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      selectedStatus:
          clearFilter ? null : (selectedStatus ?? this.selectedStatus),
    );
  }

  @override
  List<Object?> get props => [orders, filteredOrders, selectedStatus];
}

/// Error state when order retrieval fails.
class OrdersError extends OrdersState {
  final String message;

  const OrdersError(this.message);

  @override
  List<Object?> get props => [message];
}
