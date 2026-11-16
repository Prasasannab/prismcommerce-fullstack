import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/cart_item_model.dart';
import '../data/repositories/cart_repository.dart';
import 'cart_event.dart';
import 'cart_state.dart';

export 'cart_event.dart';
export 'cart_state.dart';

/// Central BLoC managing shopping cart logic, real-time math, promo codes,
/// and offline persistence.
class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _cartRepository;

  CartBloc({CartRepository? cartRepository})
      : _cartRepository = cartRepository ?? CartRepository(),
        super(const CartState()) {
    on<CartStarted>(_onCartStarted);
    on<CartItemAdded>(_onCartItemAdded);
    on<CartItemRemoved>(_onCartItemRemoved);
    on<CartItemQuantityUpdated>(_onCartItemQuantityUpdated);
    on<CartPromoCodeApplied>(_onCartPromoCodeApplied);
    on<CartPromoCodeRemoved>(_onCartPromoCodeRemoved);
    on<CartCleared>(_onCartCleared);
  }

  Future<void> _onCartStarted(
    CartStarted event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final items = await _cartRepository.loadCart();
      emit(state.copyWith(items: items, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load offline cart: $e',
        ),
      );
    }
  }

  Future<void> _onCartItemAdded(
    CartItemAdded event,
    Emitter<CartState> emit,
  ) async {
    final currentItems = List<CartItemModel>.from(state.items);
    final newItem = event.item;

    final existingIndex = currentItems.indexWhere(
      (item) =>
          item.productId == newItem.productId &&
          item.variantId == newItem.variantId,
    );

    if (existingIndex >= 0) {
      final existing = currentItems[existingIndex];
      final newQty = existing.quantity + newItem.quantity;
      final clampedQty = existing.maxStock > 0
          ? newQty.clamp(1, existing.maxStock)
          : newQty;
      currentItems[existingIndex] = existing.copyWith(quantity: clampedQty);
    } else {
      final clampedQty = newItem.maxStock > 0
          ? newItem.quantity.clamp(1, newItem.maxStock)
          : newItem.quantity;
      currentItems.add(newItem.copyWith(quantity: clampedQty));
    }

    await _cartRepository.saveCart(currentItems);
    emit(state.copyWith(items: currentItems));
  }

  Future<void> _onCartItemRemoved(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) async {
    final updated = state.items.where((item) {
      final matchProduct = item.productId == event.productId;
      final matchVariant = item.variantId == event.variantId;
      return !(matchProduct && matchVariant);
    }).toList();

    await _cartRepository.saveCart(updated);
    emit(state.copyWith(items: updated));
  }

  Future<void> _onCartItemQuantityUpdated(
    CartItemQuantityUpdated event,
    Emitter<CartState> emit,
  ) async {
    if (event.quantity <= 0) {
      add(CartItemRemoved(
        productId: event.productId,
        variantId: event.variantId,
      ));
      return;
    }

    final updated = state.items.map((item) {
      if (item.productId == event.productId &&
          item.variantId == event.variantId) {
        final clamped = item.maxStock > 0
            ? event.quantity.clamp(1, item.maxStock)
            : event.quantity;
        return item.copyWith(quantity: clamped);
      }
      return item;
    }).toList();

    await _cartRepository.saveCart(updated);
    emit(state.copyWith(items: updated));
  }

  void _onCartPromoCodeApplied(
    CartPromoCodeApplied event,
    Emitter<CartState> emit,
  ) {
    final normalized = event.code.trim().toUpperCase();
    if (normalized == 'TECH') {
      emit(
        state.copyWith(
          promoCode: 'TECH',
          isPromoApplied: true,
          promoDiscountPercent: 0.20,
          clearPromoError: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          promoError: 'Invalid promo code. Enter "TECH" for 20% off.',
          clearPromo: true,
        ),
      );
    }
  }

  void _onCartPromoCodeRemoved(
    CartPromoCodeRemoved event,
    Emitter<CartState> emit,
  ) {
    emit(
      state.copyWith(
        clearPromo: true,
        clearPromoError: true,
      ),
    );
  }

  Future<void> _onCartCleared(
    CartCleared event,
    Emitter<CartState> emit,
  ) async {
    await _cartRepository.clearCart();
    emit(const CartState());
  }
}
