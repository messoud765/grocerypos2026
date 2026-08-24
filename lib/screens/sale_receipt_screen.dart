import 'package:flutter/material.dart';
import '../providers/cart_provider.dart';
import '../utils/app_theme.dart';

// Shown right after a successful checkout: a simple digital receipt.
class SaleReceiptScreen extends StatelessWidget {
  final int saleId;
  final List<CartItem> items;
  final double total;
  final String cashierName;

  const SaleReceiptScreen({
    super.key,
    required this.saleId,
    required this.items,
    required this.total,
    required this.cashierName,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('تمت عملية البيع')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: AppColors.primary, size: 70),
              const SizedBox(height: 10),
              const Text('البيع تم بنجاح!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('رقم الفاتورة: #$saleId',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('${now.day}/${now.month}/${now.year} - ${now.hour}:${now.minute.toString().padLeft(2, '0')}'),
                        Text('الكاشير: $cashierName'),
                        const Divider(height: 24),
                        Expanded(
                          child: ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Text('${item.subtotal.toStringAsFixed(2)} DH'),
                                    const Spacer(),
                                    Text('x${item.quantity.toStringAsFixed(0)}'),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(item.product.name,
                                          textAlign: TextAlign.right),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${total.toStringAsFixed(2)} DH',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                            const Text('المجموع الكلي',
                                style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('بيع جديد'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
