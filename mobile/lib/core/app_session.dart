import 'package:flutter/widgets.dart';

import '../models/domain_models.dart';
import '../repositories/auth_repository.dart';

class AppSession extends ChangeNotifier {
  AppSession(this._auth);

  final AuthRepository _auth;
  AppUser? user;
  bool isInitializing = true;
  bool isSubmitting = false;
  String? errorMessage;

  bool get isAuthenticated => user != null;

  Future<void> initialize() async {
    try {
      final token = await _auth.restoreToken();
      if (token != null) user = await _auth.me();
    } catch (_) {
      await _auth.logout();
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      user = await _auth.login(email, password);
      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isSubmitting = true;
    notifyListeners();
    await _auth.logout();
    user = null;
    isSubmitting = false;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppSession> {
  const AppScope({required AppSession session, required super.child, super.key})
      : super(notifier: session);

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No se encontró AppScope en el árbol de widgets.');
    return scope!.notifier!;
  }
}
