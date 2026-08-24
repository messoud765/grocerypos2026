import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import 'barcode_scanner_screen.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product; // null = adding a new product

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _categoryController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minQuantityController;
  String _unit = 'piece';

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _categoryController = TextEditingController(text: p?.category ?? '');
    _purchasePriceController =
        TextEditingController(text: p?.purchasePrice.toString() ?? '');
    _salePriceController =
        TextEditingController(text: p?.salePrice.toString() ?? '');
    _quantityController =
        TextEditingController(text: p?.quantity.toString() ?? '');
    _minQuantityController =
        TextEditingController(text: p?.minQuantity.toString() ?? '5');
    _unit = p?.unit ?? 'piece';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code != null && mounted) {
      setState(() => _barcodeController.text = code);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final product = ProductModel(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim(),
      category: _categoryController.text.trim(),
      purchasePrice: double.parse(_purchasePriceController.text),
      salePrice: double.parse(_salePriceController.text),
      quantity: double.parse(_quantityController.text),
      minQuantity: double.parse(_minQuantityController.text),
      unit: _unit,
    );

    final provider = context.read<ProductProvider>();
    if (isEditing) {
      await provider.updateProduct(product);
    } else {
      await provider.addProduct(product);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'تم التعديل' : 'تمت الإضافة')),
      );
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'هاد الحقل خاصو يعمر';
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'خاصك دخل رقم';
    if (double.tryParse(value) == null) return 'رقم غير صحيح';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل منتوج' : 'منتوج جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(labelText: 'اسم المنتوج'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _barcodeController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'الباركود (اختياري)',
                prefixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'سكان الباركود',
                  onPressed: _scanBarcode,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(labelText: 'الفئة (مثلا: ألبان، خضر...)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _purchasePriceController,
                    textAlign: TextAlign.right,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'ثمن الشراء'),
                    validator: _numberValidator,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _salePriceController,
                    textAlign: TextAlign.right,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'ثمن البيع'),
                    validator: _numberValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    textAlign: TextAlign.right,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'الكمية الحالية'),
                    validator: _numberValidator,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _minQuantityController,
                    textAlign: TextAlign.right,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'حد التنبيه'),
                    validator: _numberValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: const InputDecoration(labelText: 'وحدة القياس'),
              items: const [
                DropdownMenuItem(value: 'piece', child: Text('قطعة')),
                DropdownMenuItem(value: 'kg', child: Text('كيلوغرام')),
                DropdownMenuItem(value: 'L', child: Text('لتر')),
                DropdownMenuItem(value: 'box', child: Text('علبة')),
              ],
              onChanged: (value) => setState(() => _unit = value!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة المنتوج'),
            ),
          ],
        ),
      ),
    );
  }
}
