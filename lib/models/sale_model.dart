// Represents one sale/transaction
class SaleModel {
  final int? id;
  final DateTime date;
  final double total;
  final int userId;
  final String cashierName;
  final String paymentMethod; // 'cash' or 'card'

  SaleModel({
    this.id,
    required this.date,
    required this.total,
    required this.userId,
    required this.cashierName,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'total': total,
      'userId': userId,
      'cashierName': cashierName,
      'paymentMethod': paymentMethod,
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      total: (map['total'] as num).toDouble(),
      userId: map['userId'] as int,
      cashierName: map['cashierName'] as String,
      paymentMethod: map['paymentMethod'] as String,
    );
  }
}

// Represents one line item inside a sale
class SaleItemModel {
  final int? id;
  final int saleId;
  final int productId;
  final String productName;
  final double quantity;
  final double price; // unit price at time of sale
  final double subtotal;

  SaleItemModel({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      id: map['id'] as int?,
      saleId: map['saleId'] as int,
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      price: (map['price'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}
