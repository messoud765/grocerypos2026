import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';

// Singleton class that manages ALL database operations for the app.
// Every screen talks to the database only through this class.
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Simple SHA-256 hashing for passwords (never store plain text passwords)
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'grocery_pos.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        fullName TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT,
        category TEXT,
        purchasePrice REAL NOT NULL DEFAULT 0,
        salePrice REAL NOT NULL DEFAULT 0,
        quantity REAL NOT NULL DEFAULT 0,
        minQuantity REAL NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'piece'
      )
    ''');

    // Sales table (one row per checkout/transaction)
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total REAL NOT NULL,
        userId INTEGER NOT NULL,
        cashierName TEXT NOT NULL,
        paymentMethod TEXT NOT NULL
      )
    ''');

    // Sale items table (products inside each sale)
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        quantity REAL NOT NULL,
        price REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (saleId) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    // Seed a default admin account so the app is usable on first launch.
    // Username: admin | Password: admin123
    await db.insert('users', {
      'username': 'admin',
      'password': hashPassword('admin123'),
      'fullName': 'المدير',
      'role': 'admin',
    });

    // A few sample products so the POS screen isn't empty on first run.
    await db.insert('products', {
      'name': 'خبز',
      'barcode': '1001',
      'category': 'مخبزة',
      'purchasePrice': 1.0,
      'salePrice': 1.5,
      'quantity': 50,
      'minQuantity': 10,
      'unit': 'piece',
    });
    await db.insert('products', {
      'name': 'حليب 1L',
      'barcode': '1002',
      'category': 'ألبان',
      'purchasePrice': 6.0,
      'salePrice': 7.5,
      'quantity': 30,
      'minQuantity': 5,
      'unit': 'piece',
    });
    await db.insert('products', {
      'name': 'سكر',
      'barcode': '1003',
      'category': 'مواد غذائية',
      'purchasePrice': 8.0,
      'salePrice': 10.0,
      'quantity': 20,
      'minQuantity': 5,
      'unit': 'kg',
    });
  }

  // ------------------- USERS -------------------

  Future<UserModel?> getUserByUsername(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  // Returns the logged-in user if credentials are correct, otherwise null.
  Future<UserModel?> login(String username, String password) async {
    final user = await getUserByUsername(username);
    if (user == null) return null;
    if (user.passwordHash == hashPassword(password)) {
      return user;
    }
    return null;
  }

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', {
      'username': user.username,
      'password': hashPassword(user.passwordHash), // raw password passed in
      'fullName': user.fullName,
      'role': user.role,
    });
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final result = await db.query('users');
    return result.map((e) => UserModel.fromMap(e)).toList();
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------- PRODUCTS -------------------

  Future<int> insertProduct(ProductModel product) async {
    final db = await database;
    return await db.insert('products', product.toMap()..remove('id'));
  }

  Future<int> updateProduct(ProductModel product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ProductModel>> getAllProducts() async {
    final db = await database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((e) => ProductModel.fromMap(e)).toList();
  }

  // Exact match lookup, used right after scanning a barcode.
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (result.isEmpty) return null;
    return ProductModel.fromMap(result.first);
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((e) => ProductModel.fromMap(e)).toList();
  }

  // Reduce stock after a sale (or increase if quantitySold is negative, e.g. a return)
  Future<void> adjustStock(int productId, double quantitySold) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE products SET quantity = quantity - ? WHERE id = ?',
      [quantitySold, productId],
    );
  }

  // ------------------- SALES -------------------

  // Saves a full sale (header + items) and decreases stock, all in one
  // atomic transaction so the database never ends up in a half-written state.
  Future<int> createSale(SaleModel sale, List<SaleItemModel> items) async {
    final db = await database;
    late int saleId;

    await db.transaction((txn) async {
      saleId = await txn.insert('sales', sale.toMap()..remove('id'));

      for (final item in items) {
        await txn.insert('sale_items', {
          'saleId': saleId,
          'productId': item.productId,
          'productName': item.productName,
          'quantity': item.quantity,
          'price': item.price,
          'subtotal': item.subtotal,
        });

        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
    });

    return saleId;
  }

  Future<List<SaleModel>> getAllSales() async {
    final db = await database;
    final result = await db.query('sales', orderBy: 'date DESC');
    return result.map((e) => SaleModel.fromMap(e)).toList();
  }

  Future<List<SaleModel>> getSalesBetween(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'sales',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return result.map((e) => SaleModel.fromMap(e)).toList();
  }

  Future<List<SaleItemModel>> getSaleItems(int saleId) async {
    final db = await database;
    final result = await db.query(
      'sale_items',
      where: 'saleId = ?',
      whereArgs: [saleId],
    );
    return result.map((e) => SaleItemModel.fromMap(e)).toList();
  }
}
