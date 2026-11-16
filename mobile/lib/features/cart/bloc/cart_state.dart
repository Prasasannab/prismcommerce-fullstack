import 'package:equatable/equatable.dart';
import '../data/models/cart_item_model.dart';

/// State of the shopping cart including line items, discounts, shipping, and totals.
class CartState extends Equatable {
  final List<CartItemModel> items;
  final String? promoCode;
  final bool isPromoApplied;
  final double promoDiscountPercent;
  final String? promoError;
  final bool isLoading;
  final String? errorMessage;

  const CartState({
    this.items = const [],
    this.promoCode,
    this.isPromoApplied = false,
    this.promoDiscountPercent = 0.0,
    this.promoError,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Total count of physical units across all line items in the cart.
  int get totalItemCount =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  /// Subtotal sum of all items before discounts and shipping.
  double get subtotal =>
      items.fold<double>(0.0, (sum, item) => sum + item.totalPrice);

  /// Discount amount in dollars based on active promo code.
  double get promoDiscount =>
      isPromoApplied ? (subtotal * promoDiscountPercent) : 0.0;

  /// Shipping cost: $0 for orders with subtotal > $100, else $15 ($0 if cart is empty).
  double get shipping {
    if (items.isEmpty) return 0.0;
    return subtotal > 100.0 ? 0.0 : 15.0;
  }

  /// Final total amount due (subtotal - discount + shipping).
  double get total {
    if (items.isEmpty) return 0.0;
    final amount = (subtotal - promoDiscount) + shipping;
    return amount > 0.0 ? amount : 0.0;
  }

  /// Whether user has qualified for free shipping.
  bool get hasFreeShipping => items.isNotEmpty && subtotal > 100.0;

  /// Amount needed to reach free shipping threshold ($100), or 0 if already qualified.
  double get freeShippingDeficit {
    if (items.isEmpty || subtotal >= 100.0) return 0.0;
    return 100.0 - subtotal;
  }

  CartState copyWith({
    List<CartItemModel>? items,
    String? promoCode,
    bool? isPromoApplied,
    double? promoDiscountPercent,
    String? promoError,
    bool clearPromoError = false,
    bool clearPromo = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      promoCode: clearPromo ? null : (promoCode ?? this.promoCode),
      isPromoApplied:
          clearPromo ? false : (isPromoApplied ?? this.isPromoApplied),
      promoDiscountPercent: clearPromo
          ? 0.0
          : (promoDiscountPercent ?? this.promoDiscountPercent),
      promoError: clearPromoError
          ? null
          : (promoError ?? (clearPromo ? null : this.promoError)),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        items,
        promoCode,
        isPromoApplied,
        promoDiscountPercent,
        promoError,
        isLoading,
        errorMessage,
      ];
}
