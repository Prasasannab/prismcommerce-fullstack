import 'package:flutter_bloc/flutter_bloc.dart';
import '../../checkout/data/models/order_response_model.dart';
import '../data/repositories/orders_repository.dart';
import 'orders_event.dart';
import 'orders_state.dart';

export 'orders_event.dart';
export 'orders_state.dart';

/// Central BLoC managing order history fetching, pull-to-refresh,
/// and live status filtering (All, Active, Delivered, Cancelled).
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrdersRepository _ordersRepository;

  OrdersBloc({OrdersRepository? ordersRepository})
      : _ordersRepository = ordersRepository ?? OrdersRepository(),
        super(const OrdersInitial()) {
    on<OrdersStarted>(_onOrdersStarted);
    on<OrdersRefreshed>(_onOrdersRefreshed);
    on<OrderStatusFilterSelected>(_onOrderStatusFilterSelected);
  }

  Future<void> _onOrdersStarted(
    OrdersStarted event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrdersLoading());
    try {
      final orders = await _ordersRepository.getMyOrders();
      emit(OrdersLoaded(
        orders: orders,
        filteredOrders: orders,
        selectedStatus: null,
      ));
    } catch (e) {
      emit(OrdersError('Failed to load orders: $e'));
    }
  }

  Future<void> _onOrdersRefreshed(
    OrdersRefreshed event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      final orders = await _ordersRepository.getMyOrders();
      final currentFilter =
          state is OrdersLoaded ? (state as OrdersLoaded).selectedStatus : null;

      final filtered = _filterOrders(orders, currentFilter);
      emit(OrdersLoaded(
        orders: orders,
        filteredOrders: filtered,
        selectedStatus: currentFilter,
      ));
    } catch (e) {
      emit(OrdersError('Failed to refresh orders: $e'));
    }
  }

  void _onOrderStatusFilterSelected(
    OrderStatusFilterSelected event,
    Emitter<OrdersState> emit,
  ) {
    if (state is OrdersLoaded) {
      final current = state as OrdersLoaded;
      final filtered = _filterOrders(current.orders, event.status);
      emit(current.copyWith(
        selectedStatus: event.status,
        filteredOrders: filtered,
        clearFilter: event.status == null || event.status == 'All',
      ));
    }
  }

  List<OrderResponseModel> _filterOrders(
    List<OrderResponseModel> allOrders,
    String? status,
  ) {
    if (status == null ||
        status.trim().isEmpty ||
        status.trim().toLowerCase() == 'all') {
      return allOrders;
    }

    final normalized = status.trim().toLowerCase();
    if (normalized == 'active') {
      return allOrders.where((order) {
        final s = order.status.trim().toLowerCase();
        return s == 'pending' ||
            s == 'paid' ||
            s == 'processing' ||
            s == 'shipped';
      }).toList();
    }

    return allOrders.where((order) {
      final s = order.status.trim().toLowerCase();
      return s == normalized;
    }).toList();
  }
}
