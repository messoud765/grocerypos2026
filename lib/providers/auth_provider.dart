import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/db_helper.dart';

// Manages who is currently logged in, and exposes that to the whole app.
class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final user = await DBHelper.instance.login(username.trim(), password);

    _isLoading = false;
    if (user == null) {
      _errorMessage = 'اسم المستخدم أو كلمة السر غير صحيحة';
      notifyListeners();
      return false;
    }

    _currentUser = user;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
