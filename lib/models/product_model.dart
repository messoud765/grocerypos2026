// Represents a product in the store inventory
class ProductModel {
  final int? id;
  final String name;
  final String barcode;
  final String category;
  final double purchasePrice; // cost price
  final double salePrice; // selling price
  final double quantity; // current stock
  final double minQuantity; // alert threshold
  final String unit; // e.g. "piece", "kg", "L"

  ProductModel({
    this.id,
    required this.name,
    required this.barcode,
    required this.category,
    required this.purchasePrice,
    required this.salePrice,
    required this.quantity,
    required this.minQuantity,
    required this.unit,
  });

  bool get isLowStock => quantity <= minQuantity;

  double get profitMargin => salePrice - purchasePrice;

  ProductModel copyWith({
    int? id,
    String? name,
    String? barcode,
    String? category,
    double? purchasePrice,
    double? salePrice,
    double? quantity,
    double? minQuantity,
    String? unit,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category': category,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'unit': unit,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      barcode: map['barcode'] as String,
      category: map['category'] as String,
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      salePrice: (map['salePrice'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      minQuantity: (map['minQuantity'] as num).toDouble(),
      unit: map['unit'] as String,
    );
  }
}
