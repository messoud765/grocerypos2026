import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../models/user_model.dart';
import '../services/db_helper.dart';

// One line in the cart: a product + how many units are being sold.
class CartItem {
  final ProductModel product;
  double quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.salePrice * quantity;
}

// Manages the cart on the POS (cashier) screen: adding items, changing
// quantities, computing the total, and finalizing the sale.
class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {}; // key = productId

  List<CartItem> get items => _items.values.toList();

  int get itemCount => _items.length;

  double get total =>
      _items.values.fold(0.0, (sum, item) => sum + item.subtotal);

  void addProduct(ProductModel product) {
    if (_items.containsKey(product.id)) {
      _items[product.id!]!.quantity += 1;
    } else {
      _items[product.id!] = CartItem(product: product);
    }
    notifyListeners();
  }

  void setQuantity(int productId, double quantity) {
    if (quantity <= 0) {
      _items.remove(productId);
    } else if (_items.containsKey(productId)) {
      _items[productId]!.quantity = quantity;
    }
    notifyListeners();
  }

  void removeProduct(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  // Saves the sale to the database and reduces stock for every item.
  // Returns the new sale's id.
  Future<int> checkout({
    required UserModel cashier,
    required String paymentMethod,
  }) async {
    final sale = SaleModel(
      date: DateTime.now(),
      total: total,
      userId: cashier.id!,
      cashierName: cashier.fullName,
      paymentMethod: paymentMethod,
    );

    final saleItems = _items.values
        .map((item) => SaleItemModel(
              saleId: 0, // filled in by DBHelper
              productId: item.product.id!,
              productName: item.product.name,
              quantity: item.quantity,
              price: item.product.salePrice,
              subtotal: item.subtotal,
            ))
        .toList();

    final saleId = await DBHelper.instance.createSale(sale, saleItems);
    clear();
    return saleId;
  }
}
