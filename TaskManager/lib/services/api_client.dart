import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Client HTTP dùng chung: tự gắn token, giải mã JSON, chuẩn hóa lỗi.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _token;

  /// Được gọi khi server trả 401 trong lúc đang có token (hết hạn / không hợp lệ).
  void Function()? onUnauthorized;

  void setToken(String? token) => _token = token;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.toString().isNotEmpty) q[k] = v.toString();
    });
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    return q.isEmpty ? uri : uri.replace(queryParameters: q);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => http.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, [Object? body]) =>
      _send(() => http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> put(String path, [Object? body]) =>
      _send(() => http.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> patch(String path, [Object? body]) =>
      _send(() => http.patch(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path) =>
      _send(() => http.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final res = await request().timeout(const Duration(seconds: 20));
      dynamic body;
      if (res.body.isNotEmpty) {
        try {
          body = jsonDecode(utf8.decode(res.bodyBytes));
        } catch (_) {}
      }
      if (res.statusCode >= 200 && res.statusCode < 300) return body;

      var message = 'Có lỗi xảy ra (${res.statusCode})';
      if (body is Map) {
        final m = body['message'];
        if (m is String && m.isNotEmpty) message = m;
        final errs = body['errors'];
        if (errs is List && errs.isNotEmpty) {
          final msgs = errs
              .map((e) => e is Map ? e['message']?.toString() : null)
              .whereType<String>()
              .toSet()
              .toList();
          if (msgs.isNotEmpty) message = msgs.join('\n');
        }
      }
      if (res.statusCode == 401 && _token != null) onUnauthorized?.call();
      throw ApiException(message, statusCode: res.statusCode);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Máy chủ phản hồi quá lâu, vui lòng thử lại');
    } catch (_) {
      throw ApiException('Không thể kết nối tới máy chủ. Hãy kiểm tra mạng và địa chỉ API.');
    }
  }
}
