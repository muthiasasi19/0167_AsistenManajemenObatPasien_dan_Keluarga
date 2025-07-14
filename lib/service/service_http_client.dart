import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class ServiceHttpClient {
  final String baseUrl =
      'http://192.168.147.75:3000/api/'; // Ganti sesuai IP dan port. Kalau di Chrome, 127.0.0.1 . Kalau Android Emulator, coba 'http://10.0.2.2:3000/api/'
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

  //  Metode  untuk POST dengan multipart/form-data (untuk upload file)
  Future<http.Response> postMultipart(
    String endpoint,
    Map<String, String> fields, // Data non-file
    File? file, // File yang akan diupload, bisa null
    String fileField, // Nama field untuk file di backend (misal: 'photo')
  ) async {
    final token = await secureStorage.read(key: 'authToken');
    final uri = Uri.parse('$baseUrl$endpoint');
    var request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Tambahkan fields data
    fields.forEach((key, value) {
      request.fields[key] = value;
    });

    // Tambahkan file jika ada
    if (file != null) {
      try {
        final fileName = path.basename(file.path);
        final fileExtension = path.extension(fileName).toLowerCase();

        MediaType contentType;
        switch (fileExtension) {
          case '.png':
            contentType = MediaType('image', 'png');
            break;
          case '.jpg':
          case '.jpeg':
            contentType = MediaType('image', 'jpeg');
            break;
          case '.gif':
            contentType = MediaType('image', 'gif');
            break;
          default:
            contentType = MediaType('application', 'octet-stream'); // Default
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            fileField, // Nama field yang diharapkan backend (e.g., 'photo')
            file.path,
            filename: fileName,
            contentType: contentType,
          ),
        );
        developer.log(
          'HttpClient: [TOKEN] MULTIPART POST - File added: $fileName',
        );
      } catch (e) {
        developer.log('HttpClient: Error adding file to multipart request: $e');
        rethrow;
      }
    }

    developer.log('HttpClient: [TOKEN] Sending MULTIPART POST to $uri');
    developer.log('HttpClient: MULTIPART POST fields: $fields');

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      developer.log(
        'HttpClient: [TOKEN] MULTIPART POST Response Status: ${response.statusCode}',
      );
      developer.log(
        'HttpClient: [TOKEN] MULTIPART POST Response Body: ${response.body}',
      );
      return response;
    } catch (e) {
      developer.log('HttpClient: [TOKEN] MULTIPART POST request failed: $e');
      throw Exception('MULTIPART POST with token failed: $e');
    }
  }

  // Metode  untuk PUT dengan multipart/form-data (untuk upload file)
  Future<http.Response> putMultipart(
    String endpoint,
    Map<String, String> fields,
    File? file, // File yang akan diupload, bisa null
    String fileField, // Nama field untuk file di backend (misal: 'photo')
  ) async {
    final token = await secureStorage.read(key: 'authToken');
    final uri = Uri.parse('$baseUrl$endpoint');
    var request = http.MultipartRequest('PUT', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Tambahkan fields data
    fields.forEach((key, value) {
      request.fields[key] = value;
    });

    // Tambahkan file jika ada
    if (file != null) {
      try {
        final fileName = path.basename(file.path);
        final fileExtension = path.extension(fileName).toLowerCase();

        MediaType contentType;
        switch (fileExtension) {
          case '.png':
            contentType = MediaType('image', 'png');
            break;
          case '.jpg':
          case '.jpeg':
            contentType = MediaType('image', 'jpeg');
            break;
          case '.gif':
            contentType = MediaType('image', 'gif');
            break;
          default:
            contentType = MediaType('application', 'octet-stream'); // Default
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            fileField, // Nama field yang diharapkan backend (e.g., 'photo')
            file.path,
            filename: fileName,
            contentType: contentType,
          ),
        );
        developer.log(
          'HttpClient: [TOKEN] MULTIPART PUT - File added: $fileName',
        );
      } catch (e) {
        developer.log(
          'HttpClient: Error adding file to multipart request (PUT): $e',
        );
        rethrow;
      }
    }

    developer.log('HttpClient: [TOKEN] Sending MULTIPART PUT to $uri');
    developer.log('HttpClient: MULTIPART PUT fields: $fields');

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      developer.log(
        'HttpClient: [TOKEN] MULTIPART PUT Response Status: ${response.statusCode}',
      );
      developer.log(
        'HttpClient: [TOKEN] MULTIPART PUT Response Body: ${response.body}',
      );
      return response;
    } catch (e) {
      developer.log('HttpClient: [TOKEN] MULTIPART PUT request failed: $e');
      throw Exception('MULTIPART PUT with token failed: $e');
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
