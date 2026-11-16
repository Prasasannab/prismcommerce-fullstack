import '../../../../core/storage/storage_service.dart';
import '../models/cart_item_model.dart';

/// Repository managing offline-first shopping cart persistence powered by Hive.
class CartRepository {
  final StorageService? storageService;

  CartRepository({this.storageService});

  StorageService get _storage => storageService ?? StorageService.instance;

  /// Retrieves cart items currently persisted in local storage.
  Future<List<CartItemModel>> loadCart() async {
    final rawList = _storage.getCart();
    return rawList
        .map((item) => CartItemModel.fromJson(item))
        .where((item) => item.productId.isNotEmpty && item.quantity > 0)
        .toList();
  }

  /// Persists full cart item list to local storage.
  Future<void> saveCart(List<CartItemModel> items) async {
    final rawList = items.map((item) => item.toJson()).toList();
    await _storage.saveCart(rawList);
  }

  /// Clears persisted cart items from local storage.
  Future<void> clearCart() async {
    await _storage.clearCart();
  }
}
