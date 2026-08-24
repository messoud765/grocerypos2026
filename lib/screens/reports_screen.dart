import 'package:flutter/material.dart';
import '../models/sale_model.dart';
import '../services/db_helper.dart';
import '../utils/app_theme.dart';
import 'sale_detail_view_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<SaleModel> _allSales = [];
  bool _isLoading = true;

  double _todayTotal = 0;
  double _weekTotal = 0;
  double _monthTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final sales = await DBHelper.instance.getAllSales();

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    double today = 0, week = 0, month = 0;
    for (final sale in sales) {
      if (sale.date.isAfter(startOfToday)) today += sale.total;
      if (sale.date.isAfter(startOfWeek)) week += sale.total;
      if (sale.date.isAfter(startOfMonth)) month += sale.total;
    }

    setState(() {
      _allSales = sales;
      _todayTotal = today;
      _weekTotal = week;
      _monthTotal = month;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: 'اليوم', value: _todayTotal, color: AppColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(label: 'هاد الأسبوع', value: _weekTotal, color: AppColors.accent)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _StatCard(label: 'هاد الشهر', value: _monthTotal, color: AppColors.primaryDark, fullWidth: true),
                  const SizedBox(height: 20),
                  const Text(
                    'آخر المبيعات',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_allSales.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: Text('ما كاينش مبيعات بعد')),
                    )
                  else
                    ..._allSales.take(30).map((sale) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SaleDetailViewScreen(sale: sale),
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Icon(
                                sale.paymentMethod == 'cash'
                                    ? Icons.money
                                    : Icons.credit_card,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              '${sale.total.toStringAsFixed(2)} DH',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${sale.cashierName} • ${sale.date.day}/${sale.date.month} ${sale.date.hour}:${sale.date.minute.toString().padLeft(2, '0')}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.chevron_left),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool fullWidth;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${value.toStringAsFixed(2)} DH',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
