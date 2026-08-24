import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/db_helper.dart';

// Manages the list of products (inventory) and keeps the UI in sync
// whenever a product is added, edited, deleted, or sold.
class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  String _searchQuery = '';
  bool _isLoading = false;

  List<ProductModel> get products {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.barcode.contains(_searchQuery))
        .toList();
  }

  List<ProductModel> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();

  bool get isLoading => _isLoading;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    _products = await DBHelper.instance.getAllProducts();
    _isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addProduct(ProductModel product) async {
    await DBHelper.instance.insertProduct(product);
    await loadProducts();
  }

  Future<void> updateProduct(ProductModel product) async {
    await DBHelper.instance.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    await DBHelper.instance.deleteProduct(id);
    await loadProducts();
  }
}
