import 'package:equatable/equatable.dart';
import '../data/models/cart_item_model.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

/// Initializes and loads persisted cart items from storage.
class CartStarted extends CartEvent {
  const CartStarted();
}

/// Adds a new product variant or increments quantity if already present.
class CartItemAdded extends CartEvent {
  final CartItemModel item;

  const CartItemAdded(this.item);

  @override
  List<Object?> get props => [item];
}

/// Removes a specific product variant completely from the cart.
class CartItemRemoved extends CartEvent {
  final String productId;
  final String variantId;

  const CartItemRemoved({
    required this.productId,
    required this.variantId,
  });

  @override
  List<Object?> get props => [productId, variantId];
}

/// Updates the quantity of a specific cart item, removing if quantity <= 0.
class CartItemQuantityUpdated extends CartEvent {
  final String productId;
  final String variantId;
  final int quantity;

  const CartItemQuantityUpdated({
    required this.productId,
    required this.variantId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, variantId, quantity];
}

/// Applies a promo discount code (e.g., "TECH" for 20% discount).
class CartPromoCodeApplied extends CartEvent {
  final String code;

  const CartPromoCodeApplied(this.code);

  @override
  List<Object?> get props => [code];
}

/// Removes the active promo discount code.
class CartPromoCodeRemoved extends CartEvent {
  const CartPromoCodeRemoved();
}

/// Completely clears all items and discounts from the cart.
class CartCleared extends CartEvent {
  const CartCleared();
}
