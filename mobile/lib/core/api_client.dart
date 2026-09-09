import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.errors = const []});

  final String message;
  final int? statusCode;
  final List<String> errors;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;
  String? token;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => _send('GET', path, query: query);

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) => _send('POST', path, body: body);

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) => _send('PUT', path, body: body);

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) => _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final queryParameters = query?.map((key, value) => MapEntry(key, value.toString()));
    final uri = Uri.parse('$cleanBase$cleanPath').replace(queryParameters: queryParameters);
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
      if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
    };

    try {
      late http.Response response;
      final encoded = body == null ? null : jsonEncode(body);
      switch (method) {
        case 'POST':
          response = await _http.post(uri, headers: headers, body: encoded).timeout(const Duration(seconds: 12));
          break;
        case 'PUT':
          response = await _http.put(uri, headers: headers, body: encoded).timeout(const Duration(seconds: 12));
          break;
        case 'PATCH':
          response = await _http.patch(uri, headers: headers, body: encoded).timeout(const Duration(seconds: 12));
          break;
        case 'DELETE':
          response = await _http.delete(uri, headers: headers).timeout(const Duration(seconds: 12));
          break;
        default:
          response = await _http.get(uri, headers: headers).timeout(const Duration(seconds: 12));
          break;
      }

      final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        final flattenedErrors = <String>[];
        final rawErrors = map['errors'];
        if (rawErrors is Map) {
          for (final value in rawErrors.values) {
            if (value is List) flattenedErrors.addAll(value.map((item) => item.toString()));
            if (value is String) flattenedErrors.add(value);
          }
        } else if (rawErrors is List) {
          flattenedErrors.addAll(rawErrors.map((item) => item.toString()));
        }
        throw ApiException(
          map['message']?.toString() ?? 'No fue posible completar la solicitud.',
          statusCode: response.statusCode,
          errors: flattenedErrors,
        );
      }

      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) return decoded['data'];
      return decoded;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('No hay conexión con el servidor. Verifica la red y la dirección de la API.');
    } on FormatException {
      throw const ApiException('El servidor devolvió una respuesta no válida.');
    } catch (error) {
      if (error.toString().contains('TimeoutException')) {
        throw const ApiException('El servidor tardó demasiado en responder.');
      }
      throw ApiException('Error de comunicación: $error');
    }
  }
}
