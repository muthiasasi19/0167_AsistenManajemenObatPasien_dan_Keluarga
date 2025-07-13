import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class ServiceHttpClient {
  final String baseUrl =
      'http://192.168.147.58:3000/api/'; // Ganti sesuai IP dan port. Kalau di Chrome, 127.0.0.1 . Kalau Android Emulator, coba 'http://10.0.2.2:3000/api/'
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return await secureStorage.read(key: 'authToken');
  }

  // Helper untuk mendapatkan headers
  Future<Map<String, String>> _getHeaders(String? token) async {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// POST request tanpa token
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    developer.log('HttpClient: [PUBLIC] POST Request to $url');
    developer.log('HttpClient: Request Body: ${jsonEncode(body)}');

    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(null),
        body: jsonEncode(body),
      );
      developer.log(
        'HttpClient: [PUBLIC] POST Response Status: ${response.statusCode}',
      );
      developer.log(
        'HttpClient: [PUBLIC] POST Response Body: ${response.body}',
      );
      return response;
    } catch (e) {
      developer.log('HttpClient: [PUBLIC] POST request failed: $e');
      throw Exception('POST request failed: $e');
    }
  }

  /// POST request dengan token
  Future<http.Response> postWithToken(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await secureStorage.read(key: 'authToken');
    final url = Uri.parse('$baseUrl$endpoint');
    developer.log('ServiceHttpClient: Sending POST to $url');
    developer.log('ServiceHttpClient: Token for POST: $token');

    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(token),
        body: jsonEncode(body),
      );
      developer.log(
        'HttpClient: [TOKEN] POST Response Status: ${response.statusCode}',
      );
      developer.log('HttpClient: [TOKEN] POST Response Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('HttpClient: [TOKEN] POST request failed: $e');
      throw Exception('POST with token failed: $e');
    }
  }

  /// GET request dengan token (Pencarian pasien)
  Future<http.Response> get(String endpoint) async {
    final token = await secureStorage.read(key: 'authToken');
    final url = Uri.parse('$baseUrl$endpoint');

    developer.log('ServiceHttpClient: [TOKEN] GET Request to $url');
    developer.log('ServiceHttpClient: Token for GET: $token');

    try {
      final response = await http.get(url, headers: await _getHeaders(token));
      developer.log(
        'HttpClient: [TOKEN] GET Response Status: ${response.statusCode}',
      );
      developer.log('HttpClient: [TOKEN] GET Response Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('HttpClient: [TOKEN] GET request failed: $e');
      throw Exception('GET request failed: $e');
    }
  }

  /// PUT request dengan token
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final token = await secureStorage.read(key: 'authToken');
    final url = Uri.parse('$baseUrl$endpoint');

    developer.log('HttpClient: [TOKEN] PUT Request to $url');
    developer.log('HttpClient: Token for PUT: $token');
    developer.log('HttpClient: Request Body: ${jsonEncode(body)}');

    try {
      final response = await http.put(
        url,
        headers: await _getHeaders(token),
        body: jsonEncode(body),
      );
      developer.log(
        'HttpClient: [TOKEN] PUT Response Status: ${response.statusCode}',
      );
      developer.log('HttpClient: [TOKEN] PUT Response Body: ${response.body}');
      return response;
    } catch (e) {
      developer.log('HttpClient: [TOKEN] PUT request failed: $e');
      throw Exception('PUT request failed: $e');
    }
  }

  /// DELETE request dengan token
  Future<http.Response> delete(String endpoint) async {
    final token = await secureStorage.read(key: 'authToken');
    final url = Uri.parse('$baseUrl$endpoint');

    developer.log('HttpClient: [TOKEN] DELETE Request to $url');
    developer.log('HttpClient: Token for DELETE: $token');

    try {
      final response = await http.delete(
        url,
        headers: await _getHeaders(token),
      );
      developer.log(
        'HttpClient: [TOKEN] DELETE Response Status: ${response.statusCode}',
      );
      developer.log(
        'HttpClient: [TOKEN] DELETE Response Body: ${response.body}',
      );
      return response;
    } catch (e) {
      developer.log('HttpClient: [TOKEN] DELETE request failed: $e');
      throw Exception('DELETE request failed: $e');
    }
  }
}
