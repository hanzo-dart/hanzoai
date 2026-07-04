import 'dart:async';
import 'dart:convert';

import 'jwt.dart';

/// Callback invoked whenever the stored Bearer token changes.
typedef AuthChangeCallback = void Function(String token);

/// Holds the current Hanzo IAM-issued Bearer token (a JWT or an API key).
///
/// The default [MemoryAuthStore] keeps it in memory and validates a JWT's
/// `exp` claim locally. Provide an [AsyncAuthStore] to persist the token
/// (e.g. secure storage on mobile).
abstract class AuthStore {
  String get token;

  /// Whether a usable token is present (see [isTokenValid]).
  bool get isValid => isTokenValid(token);

  void save(String token);
  void clear();

  /// Register a change listener. Returns a function that removes it.
  void Function() onChange(AuthChangeCallback callback,
      {bool fireImmediately = false});
}

/// In-memory auth store. The default when none is supplied.
class MemoryAuthStore extends AuthStore {
  String _token = '';
  final _listeners = <AuthChangeCallback>{};

  @override
  String get token => _token;

  @override
  void save(String token) {
    _token = token;
    _notify();
  }

  @override
  void clear() {
    _token = '';
    _notify();
  }

  @override
  void Function() onChange(AuthChangeCallback callback,
      {bool fireImmediately = false}) {
    _listeners.add(callback);
    if (fireImmediately) {
      callback(_token);
    }
    return () => _listeners.remove(callback);
  }

  void _notify() {
    for (final listener in _listeners.toList()) {
      listener(_token);
    }
  }
}

/// Auth store backed by an async persistence layer.
///
/// Supply [save] to persist the token and [initial] to seed the store from
/// previously-saved state. The persisted value is an opaque JSON string.
///
/// ```dart
/// AsyncAuthStore(
///   save: (data) => storage.write(key: 'hanzo_cloud', value: data),
///   initial: await storage.read(key: 'hanzo_cloud'),
/// );
/// ```
class AsyncAuthStore extends AuthStore {
  AsyncAuthStore({
    required Future<void> Function(String data) save,
    String? initial,
    Future<void> Function()? clear,
  })  : _save = save,
        _clear = clear {
    if (initial != null && initial.isNotEmpty) {
      _load(initial);
    }
  }

  final Future<void> Function(String data) _save;
  final Future<void> Function()? _clear;

  String _token = '';
  final _listeners = <AuthChangeCallback>{};

  @override
  String get token => _token;

  @override
  void save(String token) {
    _token = token;
    _notify();
    unawaited(_save(jsonEncode({'token': token})));
  }

  @override
  void clear() {
    _token = '';
    _notify();
    final clear = _clear;
    if (clear != null) {
      unawaited(clear());
    } else {
      unawaited(_save(''));
    }
  }

  @override
  void Function() onChange(AuthChangeCallback callback,
      {bool fireImmediately = false}) {
    _listeners.add(callback);
    if (fireImmediately) {
      callback(_token);
    }
    return () => _listeners.remove(callback);
  }

  void _load(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        _token = (data['token'] ?? '').toString();
      }
    } catch (_) {
      // ignore corrupt persisted state
    }
  }

  void _notify() {
    for (final listener in _listeners.toList()) {
      listener(_token);
    }
  }
}
