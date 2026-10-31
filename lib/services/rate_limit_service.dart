import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RateLimitException implements Exception {
  final Duration retryAfter;

  const RateLimitException(this.retryAfter);

  @override
  String toString() =>
      'Trop de tentatives. Réessayez dans ${retryAfter.inMinutes + 1} minute(s).';
}

class RateLimitService {
  static const int maxAttempts = 5;
  static const Duration window = Duration(minutes: 10);
  static const Duration lockout = Duration(minutes: 15);
  final Map<String, List<int>> _fallbackAttempts = {};
  final Map<String, int> _fallbackLockouts = {};

  Future<void> check(String username) async {
    final key = _key(username);
    final now = DateTime.now().millisecondsSinceEpoch;
    final prefs = await _preferences();
    final lockoutUntil =
        prefs?.getInt('${key}_lockout') ?? _fallbackLockouts[key];
    if (lockoutUntil != null && lockoutUntil > now) {
      throw RateLimitException(Duration(milliseconds: lockoutUntil - now));
    }
    if (lockoutUntil != null) {
      await prefs?.remove('${key}_lockout');
      await prefs?.remove(key);
      _fallbackLockouts.remove(key);
      _fallbackAttempts.remove(key);
    }
  }

  Future<void> recordFailure(String username) async {
    final key = _key(username);
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - window.inMilliseconds;
    final prefs = await _preferences();
    final attempts = (prefs?.getStringList(key) ??
            _fallbackAttempts[key]?.map((e) => e.toString()).toList() ??
            const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .where((timestamp) => timestamp >= cutoff)
        .toList()
      ..add(now);
    if (prefs != null) {
      await prefs.setStringList(key, attempts.map((e) => e.toString()).toList());
    } else {
      _fallbackAttempts[key] = attempts;
    }
    if (attempts.length >= maxAttempts) {
      final until = now + lockout.inMilliseconds;
      if (prefs != null) {
        await prefs.setInt('${key}_lockout', until);
      } else {
        _fallbackLockouts[key] = until;
      }
    }
  }

  Future<void> recordSuccess(String username) async {
    final key = _key(username);
    final prefs = await _preferences();
    await prefs?.remove(key);
    await prefs?.remove('${key}_lockout');
    _fallbackAttempts.remove(key);
    _fallbackLockouts.remove(key);
  }

  Future<SharedPreferences?> _preferences() async {
    try {
      return await SharedPreferences.getInstance();
    } on FlutterError {
      return null;
    }
  }

  String _key(String username) =>
      'login_attempts_${username.trim().toLowerCase()}';
}
