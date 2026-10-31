import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/user_profile.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Local accounts (stored on this device) with two roles: user and admin.
/// The FIRST account that registers becomes the admin.
class AuthService extends ChangeNotifier {
  static const _usersKey = 'users';
  static const _sessionKey = 'session';

  late SharedPreferences _prefs;
  List<AppUser> _users = [];
  String? _session;

  List<AppUser> get users => List.unmodifiable(_users);
  AppUser? get current => _session == null ? null : _find(_session!);
  bool get isAdmin => current?.role == UserRole.admin;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_usersKey);
    if (raw != null) {
      _users = (jsonDecode(raw) as List)
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _session = _prefs.getString(_sessionKey);
    if (current == null) _session = null;
  }

  AppUser? _find(String name) {
    for (final u in _users) {
      if (u.username == name) return u;
    }
    return null;
  }

  Future<void> _save() => _prefs.setString(
      _usersKey, jsonEncode(_users.map((u) => u.toJson()).toList()));

  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  String _newSalt() {
    final r = Random.secure();
    return base64UrlEncode(List.generate(16, (_) => r.nextInt(256)));
  }

  Future<void> _startSession(String name) async {
    _session = name;
    await _prefs.setString(_sessionKey, name);
    notifyListeners();
  }

  // ── validation ──
  String _validName(String username) {
    final name = username.trim().toLowerCase();
    if (name.length < 3) {
      throw AuthException('Username must be at least 3 characters');
    }
    if (!RegExp(r'^[a-z0-9_.]+$').hasMatch(name)) {
      throw AuthException('Use only letters, numbers, "_" and "."');
    }
    return name;
  }

  void _validPassword(String password) {
    if (password.length < 6) {
      throw AuthException('Password must be at least 6 characters');
    }
  }

  void _requireAdmin() {
    if (!isAdmin) throw AuthException('Admin only');
  }

  AppUser _newUser(String name, String password, UserRole role) {
    final salt = _newSalt();
    return AppUser(
      username: name,
      salt: salt,
      passwordHash: _hash(salt, password),
      role: role,
    );
  }

  // ── register / login / logout ──
  Future<void> register(String username, String password) async {
    final name = _validName(username);
    _validPassword(password);
    if (_find(name) != null) throw AuthException('Username already taken');

    _users.add(_newUser(
        name, password, _users.isEmpty ? UserRole.admin : UserRole.user));
    await _save();
    await _startSession(name);
  }

  Future<void> login(String username, String password) async {
    final u = _find(username.trim().toLowerCase());
    if (u == null || u.passwordHash != _hash(u.salt, password)) {
      throw AuthException('Wrong username or password');
    }
    await _startSession(u.username);
  }

  Future<void> logout() async {
    _session = null;
    await _prefs.remove(_sessionKey);
    notifyListeners();
  }

  // ── profile / goal ──
  Future<void> updateProfile(UserProfile p) async {
    final me = current;
    if (me == null) return;
    _users = [for (final u in _users) u.username == me.username ? u.copyWith(profile: p) : u];
    await _save();
    notifyListeners();
  }

  // ── admin actions (CRUD) ──
  /// CREATE: admin adds an account without switching sessions.
  Future<void> createUser(String username, String password, UserRole role) async {
    _requireAdmin();
    final name = _validName(username);
    _validPassword(password);
    if (_find(name) != null) throw AuthException('Username already taken');
    _users = [..._users, _newUser(name, password, role)];
    await _save();
    notifyListeners();
  }

  /// UPDATE: admin sets a new password for any user (including themselves).
  Future<void> resetPassword(String username, String newPassword) async {
    _requireAdmin();
    _validPassword(newPassword);
    final target = _find(username);
    if (target == null) throw AuthException('User not found');
    final salt = _newSalt();
    _users = [
      for (final u in _users)
        u.username == username
            ? AppUser(
          username: u.username,
          salt: salt,
          passwordHash: _hash(salt, newPassword),
          role: u.role,
          profile: u.profile,
        )
            : u
    ];
    await _save();
    notifyListeners();
  }

  /// UPDATE: change role (keeps at least one admin).
  Future<void> setRole(String username, UserRole role) async {
    _requireAdmin();
    final target = _find(username);
    if (target == null) return;
    final admins = _users.where((u) => u.role == UserRole.admin).length;
    if (target.role == UserRole.admin && role == UserRole.user && admins <= 1) {
      throw AuthException('There must be at least one admin');
    }
    _users = [for (final u in _users) u.username == username ? u.copyWith(role: role) : u];
    await _save();
    notifyListeners();
  }

  /// DELETE: remove a user (not yourself).
  Future<void> deleteUser(String username) async {
    _requireAdmin();
    if (username == _session) throw AuthException("You can't delete yourself");
    _users = _users.where((u) => u.username != username).toList();
    await _save();
    notifyListeners();
  }
}
