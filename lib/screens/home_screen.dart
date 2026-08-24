import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'pos_screen.dart';
import 'products_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

// The main shell of the app after login. Shows different tabs
// depending on whether the logged-in user is an admin or a cashier.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    // Admin sees 4 tabs, cashier only sees 2.
    final List<Widget> pages = isAdmin
        ? const [
            POSScreen(),
            ProductsScreen(),
            ReportsScreen(),
            SettingsScreen(),
          ]
        : const [
            POSScreen(),
            SettingsScreen(),
          ];

    final List<BottomNavigationBarItem> navItems = isAdmin
        ? const [
            BottomNavigationBarItem(
                icon: Icon(Icons.point_of_sale), label: 'البيع'),
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2), label: 'المنتوجات'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart), label: 'التقارير'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'الإعدادات'),
          ]
        : const [
            BottomNavigationBarItem(
                icon: Icon(Icons.point_of_sale), label: 'البيع'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'الإعدادات'),
          ];

    // Reset index safely if it goes out of range (e.g. role changes)
    if (_currentIndex >= pages.length) _currentIndex = 0;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: navItems,
      ),
    );
  }
}
