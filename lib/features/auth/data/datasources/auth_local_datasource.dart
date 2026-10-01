import 'package:chess/core/constants/app_constants.dart';
import 'package:chess/features/auth/domain/entities/user_entity.dart';
import 'package:hive/hive.dart';

/// Persists the last authenticated session for fast UI restore.
class AuthLocalDataSource {
  AuthLocalDataSource();

  static const String _uidKey = 'auth_uid';
  static const String _emailKey = 'auth_email';
  static const String _displayNameKey = 'auth_display_name';
  static const String _isAnonymousKey = 'auth_is_anonymous';

  Box<dynamic>? _box;

  Future<Box<dynamic>> _openBox() async {
    _box ??= await Hive.openBox<dynamic>(AppConstants.cacheBoxName);
    return _box!;
  }

  Future<void> saveSession(UserEntity user) async {
    final box = await _openBox();
    await box.putAll({
      _uidKey: user.uid,
      _emailKey: user.email,
      _displayNameKey: user.displayName,
      _isAnonymousKey: user.isAnonymous,
    });
  }

  Future<UserEntity?> readSession() async {
    final box = await _openBox();
    final uid = box.get(_uidKey) as String?;
    if (uid == null || uid.isEmpty) return null;

    return UserEntity(
      uid: uid,
      email: box.get(_emailKey) as String? ?? '',
      displayName: box.get(_displayNameKey) as String? ?? 'Player',
      isAnonymous: box.get(_isAnonymousKey) as bool? ?? false,
    );
  }

  Future<void> clearSession() async {
    final box = await _openBox();
    await box.delete(_uidKey);
    await box.delete(_emailKey);
    await box.delete(_displayNameKey);
    await box.delete(_isAnonymousKey);
  }
}
