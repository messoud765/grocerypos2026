import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../services/db_helper.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await DBHelper.instance.getAllUsers();
    setState(() => _users = users);
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('واش متأكد بغيتي تخرج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('خروج', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController();
    String role = 'cashier';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة مستخدم جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: usernameController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'اسم المستخدم'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'كلمة السر'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'الصلاحية'),
                  items: const [
                    DropdownMenuItem(value: 'cashier', child: Text('كاشير')),
                    DropdownMenuItem(value: 'admin', child: Text('مدير')),
                  ],
                  onChanged: (value) => setDialogState(() => role = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (usernameController.text.trim().isEmpty ||
                    passwordController.text.isEmpty ||
                    fullNameController.text.trim().isEmpty) {
                  return;
                }
                await DBHelper.instance.insertUser(UserModel(
                  username: usernameController.text.trim(),
                  passwordHash: passwordController.text, // hashed inside insertUser
                  fullName: fullNameController.text.trim(),
                  role: role,
                ));
                if (mounted) {
                  Navigator.pop(dialogContext);
                  _loadUsers();
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0] : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user.fullName, textAlign: TextAlign.right),
              subtitle: Text(
                user.isAdmin ? 'مدير' : 'كاشير',
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (auth.isAdmin) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('مستخدم جديد'),
                ),
                const Text('المستخدمون',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            ..._users.map((u) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(u.fullName, textAlign: TextAlign.right),
                    subtitle: Text(
                      '${u.username} • ${u.isAdmin ? "مدير" : "كاشير"}',
                      textAlign: TextAlign.right,
                    ),
                    trailing: u.id == user.id
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger),
                            onPressed: () async {
                              await DBHelper.instance.deleteUser(u.id!);
                              _loadUsers();
                            },
                          ),
                  ),
                )),
            const SizedBox(height: 20),
          ],
          ElevatedButton.icon(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
