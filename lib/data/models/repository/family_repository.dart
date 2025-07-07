// lib/data/models/repository/family_repository.dart
import 'dart:convert';
import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manajemen_obat/service/service_http_client.dart';
import 'package:manajemen_obat/data/models/response/connect_patient_family_response_model.dart';
import 'package:manajemen_obat/data/models/response/medication_response_model.dart';
import 'package:manajemen_obat/data/models/response/medication_history_response_model.dart';
import 'package:manajemen_obat/data/models/response/patient_location_response_model.dart';
import 'package:manajemen_obat/data/models/request/connect_patient_family_request_model.dart';

class FamilyRepository {
  final ServiceHttpClient _httpClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  FamilyRepository(this._httpClient);

  // Helper untuk mendapatkan ID internal keluarga dari local storage
  Future<int?> _getFamilyGlobalIdFromLocalStorage() async {
    final userDataString = await _secureStorage.read(key: 'userData');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      return userData['familyGlobalId'] as int?;
    }
    return null;
  }

  /// @desc Keluarga menghubungkan diri dengan pasien menggunakan kode unik pasien (id_pasien VARCHAR)
  /// @route POST /api/family/connect-to-patient
  Future<Either<String, String>> connectPatientToFamily(
    FamilyConnectRequestModel request,
  ) async {
    try {
      log(
        "FamilyRepository: Mengirim request koneksi keluarga ke pasien: ${request.patientUniqueId}",
      );
      final response = await _httpClient.postWithToken(
        'family/connect-to-patient',
        request.toMap(),
      );

      log(
        "FamilyRepository - connectPatientToFamily: Status Code: ${response.statusCode}",
      );
      log("FamilyRepository - connectPatientToFamily: Body: ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final message = responseBody['message'];
        log("FamilyRepository - connectPatientToFamily: Berhasil: $message");
        return Right(message);
      } else {
        final message =
            responseBody['message'] ?? 'Gagal menghubungkan pasien.';
        log(
          "FamilyRepository - connectPatientToFamily: Gagal (${response.statusCode}): $message",
        );
        return Left(message);
      }
    } catch (e, stackTrace) {
      log("FamilyRepository - connectPatientToFamily Error: $e\n$stackTrace");
      return Left("Terjadi kesalahan saat menghubungkan pasien.");
    }
  }
}
