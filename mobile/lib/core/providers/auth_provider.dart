import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  const AuthState.initial() : this(status: AuthStatus.unknown);

  AuthState copyWith({
    AuthStatus? status,
    Map<String, dynamic>? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

final authStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  FlutterSecureStorage get _storage => ref.read(authStorageProvider);
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  Future<AuthState> build() async {
    return _checkExistingSession();
  }

  Future<AuthState> _checkExistingSession() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) return const AuthState(status: AuthStatus.unauthenticated);

      final user = await _api.getMe();
      return AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _storage.deleteAll();
      return const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final tokens = await _api.login(email, password);
      await _storage.write(key: 'access_token', value: tokens['access_token'] as String);
      await _storage.write(key: 'refresh_token', value: tokens['refresh_token'] as String);

      final user = await _api.getMe();
      state = AsyncData(AuthState(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      state = AsyncData(AuthState(
        status: AuthStatus.unauthenticated,
        error: _parseError(e),
      ));
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    state = const AsyncLoading();
    try {
      final tokens = await _api.register(email, password, fullName);
      await _storage.write(key: 'access_token', value: tokens['access_token'] as String);
      await _storage.write(key: 'refresh_token', value: tokens['refresh_token'] as String);

      final user = await _api.getMe();
      state = AsyncData(AuthState(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      state = AsyncData(AuthState(
        status: AuthStatus.unauthenticated,
        error: _parseError(e),
      ));
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }

  String _parseError(Object e) {
    return e.toString().contains('400') || e.toString().contains('401')
        ? 'Invalid email or password'
        : 'Something went wrong. Please try again.';
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
