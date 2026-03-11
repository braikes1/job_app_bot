import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage, _dio),
      LogInterceptor(requestBody: true, responseBody: true, logPrint: _log),
    ]);
  }

  Dio get dio => _dio;

  // Auth
  Future<Map<String, dynamic>> register(String email, String password, String fullName) async {
    final res = await _dio.post('/auth/register', data: {
      'email': email, 'password': password, 'full_name': fullName,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email, 'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data as Map<String, dynamic>;
  }

  // Profiles
  Future<List<dynamic>> getProfiles() async {
    final res = await _dio.get('/profiles/');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createProfile(Map<String, dynamic> data) async {
    final res = await _dio.post('/profiles/', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(int id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/profiles/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteProfile(int id) async {
    await _dio.delete('/profiles/$id');
  }

  Future<Map<String, dynamic>> uploadResume(int profileId, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
    });
    final res = await _dio.post(
      '/profiles/$profileId/resume',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data as Map<String, dynamic>;
  }

  // Jobs
  Future<Map<String, dynamic>> tailorResume(Map<String, dynamic> data) async {
    final res = await _dio.post('/jobs/tailor', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startApply(Map<String, dynamic> data) async {
    final res = await _dio.post('/jobs/apply/start', data: data);
    return res.data as Map<String, dynamic>;
  }

  // Applications
  Future<List<dynamic>> getApplications({String? status, int limit = 50, int offset = 0}) async {
    final res = await _dio.get('/applications/', queryParameters: {
      if (status != null) 'status': status,
      'limit': limit,
      'offset': offset,
    });
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getApplication(int id) async {
    final res = await _dio.get('/applications/$id');
    return res.data as Map<String, dynamic>;
  }

  static void _log(Object object) {
    // ignore debug logs in production
  }
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  _AuthInterceptor(this._storage, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh the token
      try {
        final refreshToken = await _storage.read(key: 'refresh_token');
        if (refreshToken != null) {
          final res = await _dio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
            options: Options(headers: {'Authorization': null}),
          );
          final newAccessToken = res.data['access_token'] as String;
          await _storage.write(key: 'access_token', value: newAccessToken);

          // Retry original request
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryRes = await _dio.fetch(err.requestOptions);
          handler.resolve(retryRes);
          return;
        }
      } catch (_) {}
      // Refresh failed — clear tokens (force re-login)
      await _storage.deleteAll();
    }
    handler.next(err);
  }
}
