import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../services/db_helper.dart';
import '../utils/app_theme.dart';
import 'barcode_scanner_screen.dart';
import 'sale_receipt_screen.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (code == null || !mounted) return;

    final product = await DBHelper.instance.getProductByBarcode(code);

    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ما كاين حتى منتوج بالباركود: $code')),
      );
      return;
    }

    if (product.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} نفدات من المخزون')),
      );
      return;
    }

    context.read<CartProvider>().addProduct(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} تزادت للسلة'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CartSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'سكان الباركود',
            onPressed: _scanBarcode,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: cart.itemCount == 0 ? null : _openCart,
              ),
              if (cart.itemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${cart.itemCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'قلب على منتوج بالاسم أو الباركود...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          productProvider.search('');
                        },
                      )
                    : null,
              ),
              onChanged: productProvider.search,
            ),
          ),
          Expanded(
            child: productProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productProvider.products.isEmpty
                    ? const Center(child: Text('ما كاينش منتوجات'))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.95,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: productProvider.products.length,
                        itemBuilder: (context, index) {
                          final product = productProvider.products[index];
                          return _ProductCard(product: product);
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: cart.itemCount == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton(
                  onPressed: _openCart,
                  child: Text(
                    'السلة (${cart.itemCount}) — ${cart.total.toStringAsFixed(2)} DH',
                  ),
                ),
              ),
            ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.quantity <= 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: outOfStock
            ? null
            : () {
                context.read<CartProvider>().addProduct(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} تزادت للسلة'),
                    duration: const Duration(milliseconds: 700),
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.shopping_basket,
                    color: AppColors.primary.withOpacity(0.6),
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    outOfStock ? 'نفدت' : '${product.quantity.toStringAsFixed(0)} ${product.unit}',
                    style: TextStyle(
                      fontSize: 11,
                      color: outOfStock
                          ? AppColors.danger
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${product.salePrice.toStringAsFixed(2)} DH',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// The bottom sheet showing cart contents + checkout button
class _CartSheet extends StatelessWidget {
  const _CartSheet();

  Future<void> _checkout(BuildContext context, String paymentMethod) async {
    final cart = context.read<CartProvider>();
    final user = context.read<AuthProvider>().currentUser!;
    final productProvider = context.read<ProductProvider>();

    final items = List.of(cart.items); // snapshot before clear()
    final total = cart.total;

    final saleId = await cart.checkout(
      cashier: user,
      paymentMethod: paymentMethod,
    );

    await productProvider.loadProducts(); // refresh stock numbers

    if (context.mounted) {
      Navigator.pop(context); // close cart sheet
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SaleReceiptScreen(
            saleId: saleId,
            items: items,
            total: total,
            cashierName: user.fullName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text('السلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: cart.items.isEmpty
                    ? const Center(child: Text('السلة فارغة'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: AppColors.danger),
                                  onPressed: () => context
                                      .read<CartProvider>()
                                      .removeProduct(item.product.id!),
                                ),
                                Text(
                                  '${item.subtotal.toStringAsFixed(2)} DH',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => context
                                          .read<CartProvider>()
                                          .setQuantity(item.product.id!,
                                              item.quantity + 1),
                                    ),
                                    Text('${item.quantity.toStringAsFixed(0)}'),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      onPressed: () => context
                                          .read<CartProvider>()
                                          .setQuantity(item.product.id!,
                                              item.quantity - 1),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Text(
                                    item.product.name,
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
                    '${cart.total.toStringAsFixed(2)} DH',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                  const Text('المجموع', style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              if (cart.items.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.money),
                        label: const Text('نقدا'),
                        onPressed: () => _checkout(context, 'cash'),
