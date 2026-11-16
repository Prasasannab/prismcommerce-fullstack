import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/checkout/data/models/order_response_model.dart';
import 'package:mobile/features/orders/bloc/orders_bloc.dart';
import 'package:mobile/features/orders/data/repositories/orders_repository.dart';

class _FakeFailingOrdersRepository extends OrdersRepository {
  _FakeFailingOrdersRepository() : super(fallbackOnly: true);

  @override
  Future<List<OrderResponseModel>> getMyOrders() async {
    throw Exception('Simulated fatal database outage');
  }
}

void main() {
  group('OrdersBloc', () {
    late OrdersRepository repository;

    setUp(() {
      repository = OrdersRepository(fallbackOnly: true);
    });

    test('initial state is OrdersInitial', () {
      final bloc = OrdersBloc(ordersRepository: repository);
      expect(bloc.state, const OrdersInitial());
      bloc.close();
    });

    test('OrdersStarted emits [OrdersLoading, OrdersLoaded]', () async {
      final bloc = OrdersBloc(ordersRepository: repository);

      expectLater(
        bloc.stream,
        emitsInOrder([
          const OrdersLoading(),
          isA<OrdersLoaded>()
              .having((s) => s.orders.length, 'orders length', 5)
              .having((s) => s.filteredOrders.length, 'filtered length', 5)
              .having((s) => s.selectedStatus, 'selectedStatus', isNull),
        ]),
      );

      bloc.add(const OrdersStarted());
      await pumpEventQueue();
      await bloc.close();
    });

    test('OrderStatusFilterSelected filters list accurately by status',
        () async {
      final bloc = OrdersBloc(ordersRepository: repository);

      bloc.add(const OrdersStarted());
      await pumpEventQueue();

      // Filter by 'Active' (Pending, Paid, Shipped)
      bloc.add(const OrderStatusFilterSelected('Active'));
      await pumpEventQueue();

      var state = bloc.state as OrdersLoaded;
      expect(state.selectedStatus, 'Active');
      expect(state.filteredOrders.length, 3);
      expect(
        state.filteredOrders.every((o) =>
            o.status == 'Pending' ||
            o.status == 'Paid' ||
            o.status == 'Shipped'),
        isTrue,
      );

      // Filter by 'Delivered'
      bloc.add(const OrderStatusFilterSelected('Delivered'));
      await pumpEventQueue();

      state = bloc.state as OrdersLoaded;
      expect(state.selectedStatus, 'Delivered');
      expect(state.filteredOrders.length, 1);
      expect(state.filteredOrders.first.status, 'Delivered');

      // Filter by 'Cancelled'
      bloc.add(const OrderStatusFilterSelected('Cancelled'));
      await pumpEventQueue();

      state = bloc.state as OrdersLoaded;
      expect(state.selectedStatus, 'Cancelled');
      expect(state.filteredOrders.length, 1);
      expect(state.filteredOrders.first.status, 'Cancelled');

      // Reset to 'All'
      bloc.add(const OrderStatusFilterSelected('All'));
      await pumpEventQueue();

      state = bloc.state as OrdersLoaded;
      expect(state.selectedStatus, isNull);
      expect(state.filteredOrders.length, 5);

      await bloc.close();
    });

    test('OrdersRefreshed preserves active filter while reloading orders',
        () async {
      final bloc = OrdersBloc(ordersRepository: repository);

      bloc.add(const OrdersStarted());
      await pumpEventQueue();

      bloc.add(const OrderStatusFilterSelected('Delivered'));
      await pumpEventQueue();

      // Trigger Refresh
      bloc.add(const OrdersRefreshed());
      await pumpEventQueue();

      final state = bloc.state as OrdersLoaded;
      expect(state.selectedStatus, 'Delivered');
      expect(state.filteredOrders.length, 1);
      expect(state.filteredOrders.first.status, 'Delivered');

      await bloc.close();
    });

    test('OrdersStarted emits OrdersError on failure', () async {
      final failingRepo = _FakeFailingOrdersRepository();
      final bloc = OrdersBloc(ordersRepository: failingRepo);

      expectLater(
        bloc.stream,
        emitsInOrder([
          const OrdersLoading(),
          isA<OrdersError>().having(
            (e) => e.message,
            'message',
            contains('Simulated fatal database outage'),
          ),
        ]),
      );

      bloc.add(const OrdersStarted());
      await pumpEventQueue();
      await bloc.close();
    });
  });
}
