import 'package:flutter/material.dart';
import '../models/sale_model.dart';
import '../services/db_helper.dart';
import '../utils/app_theme.dart';

// Shows the products inside a past sale, when tapped from the Reports list.
class SaleDetailViewScreen extends StatefulWidget {
  final SaleModel sale;
  const SaleDetailViewScreen({super.key, required this.sale});

  @override
  State<SaleDetailViewScreen> createState() => _SaleDetailViewScreenState();
}

class _SaleDetailViewScreenState extends State<SaleDetailViewScreen> {
  List<SaleItemModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await DBHelper.instance.getSaleItems(widget.sale.id!);
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;

    return Scaffold(
      appBar: AppBar(title: Text('فاتورة #${sale.id}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _infoRow('الكاشير', sale.cashierName),
                          _infoRow('التاريخ',
                              '${sale.date.day}/${sale.date.month}/${sale.date.year}'),
                          _infoRow('الوقت',
                              '${sale.date.hour}:${sale.date.minute.toString().padLeft(2, '0')}'),
                          _infoRow('طريقة الدفع',
                              sale.paymentMethod == 'cash' ? 'نقدا' : 'بالكارط'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          title: Text(item.productName, textAlign: TextAlign.right),
                          subtitle: Text(
                            '${item.price.toStringAsFixed(2)} DH x ${item.quantity.toStringAsFixed(0)}',
                            textAlign: TextAlign.right,
                          ),
                          trailing: Text(
                            '${item.subtotal.toStringAsFixed(2)} DH',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${sale.total.toStringAsFixed(2)} DH',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      const Text('المجموع الكلي'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
