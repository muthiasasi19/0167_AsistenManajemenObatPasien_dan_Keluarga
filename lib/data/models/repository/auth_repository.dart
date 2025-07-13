import 'dart:convert';
import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:manajemen_obat/data/models/request/register_request_model.dart';
import 'package:manajemen_obat/data/models/request/login_request_model.dart';
import 'package:manajemen_obat/data/models/response/login_response_model.dart';
import 'package:manajemen_obat/service/service_http_client.dart';

class AuthRepository {
  final ServiceHttpClient _httpClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthRepository(this._httpClient);

  /// Register user
  Future<Either<String, String>> register(RegisterRequestModel request) async {
    try {
      final response = await _httpClient.post('auth/register', request.toMap());

      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 201) {
        final message = responseBody['message'];
        log("Register success: $message");
        return Right(message);
      } else {
        final message = responseBody['message'] ?? 'Registrasi gagal';
        log("Register failed: $message");
        return Left(message);
      }
    } catch (e, stackTrace) {
      log("Register error: $e");
      log("Stacktrace: $stackTrace");
      return Left("Terjadi kesalahan saat registrasi.");
    }
  }

  /// Login user
  Future<Either<String, LoginResponseModel>> login(
    LoginRequestModel request,
  ) async {
    try {
      final response = await _httpClient.post('auth/login', request.toMap());

      log("Status code: ${response.statusCode}");
      log("Response body: ${response.body}");

      Map<String, dynamic> responseBody;
      try {
        responseBody = jsonDecode(response.body);
      } catch (e) {
        log("Gagal decode JSON: ${response.body}");
        return Left("Format respon tidak valid dari server.");
      }

      if (response.statusCode == 200) {
        final loginResponse = LoginResponseModel.fromMap(responseBody);

        final token = loginResponse.token;

        if (token == null || token.isEmpty) {
          log('Token kosong!');
          return Left("Token tidak ditemukan di response");
        }

        await _secureStorage.write(key: 'authToken', value: token);
        await _secureStorage.write(
          key: 'userRole',
          value: loginResponse.user?.role ?? '',
        );

        if (loginResponse.user != null) {
          // Pastikan User model memiliki metode toMap() atau toJson() yang benar
          await _secureStorage.write(
            key: 'userData',
            value: jsonEncode(loginResponse.user!.toMap()),
          );
        }

        log("Login success: ${loginResponse.message}");
        return Right(loginResponse);
      } else {
        final message = responseBody['message'] ?? 'Login gagal';
        log("Login failed (${response.statusCode}): $message");
        return Left(message);
      }
    } catch (e, stackTrace) {
      log("Login error: $e");
      log("Stacktrace: $stackTrace");
      return Left("Terjadi kesalahan saat login.");
    }
  }
}
