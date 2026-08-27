import '../models/app_user.dart';

class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  bool get isLogged => _currentUser != null;

  bool get canManage => _currentUser?.canManage ?? false;

  String? get userId => _currentUser?.id;

  String? get organizationId => _currentUser?.organizationId;

  void setUser(AppUser user) {
    _currentUser = user;
  }

  void clear() {
    _currentUser = null;
  }
}