import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dartz/dartz.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manajemen_obat/service/service_http_client.dart';
import 'package:manajemen_obat/data/models/request/medication/add_medication_request_model.dart';
import 'package:manajemen_obat/data/models/request/medication/update_medication_request_model.dart';
import 'package:manajemen_obat/data/models/response/medication_response_model.dart';
import 'package:manajemen_obat/data/models/response/login_response_model.dart';
import 'package:manajemen_obat/data/models/response/medication_history_response_model.dart';
import 'package:http/http.dart' as http;

class MedicationRepository {
  final ServiceHttpClient _httpClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  MedicationRepository(this._httpClient);

  // Fungsi  untuk mendapatkan data pengguna lengkap
  Future<User?> _getCurrentUserFromLocalStorage() async {
    try {
      final userDataString = await _secureStorage.read(key: 'userData');
      if (userDataString != null) {
        final userMap = jsonDecode(userDataString);
        return User.fromMap(userMap);
      }
    } catch (e, stackTrace) {
      developer.log("Error reading user data from storage: $e\n$stackTrace");
    }
    return null;
  }

  // Fungsi pembantu untuk mendapatkan ID global dokter
  Future<int?> _getDoctorGlobalId() async {
    final currentUser = await _getCurrentUserFromLocalStorage();
    if (currentUser?.role?.toLowerCase() == 'dokter') {
      return currentUser?.doctorGlobalId;
    }
    return null;
  }

  //  FUNGSI getMedicationsByPatientId oleh dokter
  /// Mengambil daftar obat resep  untuk pasien tertentu. Hanya untuk dokter.
  Future<Either<String, MedicationsListResponseModel>>
  getMedicationsByPatientId({
    required int? patientGlobalId,
    required String? patientUniqueId,
  }) async {
    try {
      final currentUser = await _getCurrentUserFromLocalStorage();
      if (currentUser == null) {
        return const Left("Data pengguna tidak ditemukan. Mohon login ulang.");
      }

      String endpoint;
      String? targetPatientIdentifier;

      developer.log(
        '[MED_REPO:getMedicationsByPatientId] User Role: ${currentUser.role}, Req Unique ID: $patientUniqueId, Req Global ID: $patientGlobalId',
      );

      if (currentUser.role?.toLowerCase() == 'dokter') {
        if (patientUniqueId == null || patientUniqueId.isEmpty) {
          return const Left(
            'Silakan pilih pasien terlebih dahulu untuk melihat obat.',
          );
        }
        targetPatientIdentifier = patientUniqueId;
        endpoint = 'medications/patient/$targetPatientIdentifier/all';
        developer.log(
          '[MED_REPO:getMedicationsByPatientId] Dokter Role - Final Endpoint: $endpoint',
        );
      } else {
        return const Left(
          "Peran pengguna tidak valid untuk mengambil daftar obat resep. Gunakan endpoint sesi untuk pasien/keluarga.",
        );
      }

      final response = await _httpClient.get(endpoint);

      developer.log(
        '[MED_REPO:getMedicationsByPatientId] Response Status: ${response.statusCode}',
      );
      developer.log(
        '[MED_REPO:getMedicationsByPatientId] Raw Response Body: ${response.body}',
      );

      if (response.statusCode == 200) {
        try {
          final responseModel = MedicationsListResponseModel.fromJson(
            response.body,
          );
          developer.log(
            '[MED_REPO:getMedicationsByPatientId] Success: ${responseModel.data.length} medications loaded.',
          );
          return Right(responseModel);
        } catch (jsonError, st) {
          developer.log(
            '[MED_REPO:getMedicationsByPatientId] JSON Parsing Error: $jsonError\n$st',
          );
          return const Left(
            "Gagal memproses data obat dari server. Format data tidak valid.",
          );
        }
      } else {
        String message = 'Gagal memuat daftar obat.';
        try {
          final errorBody = jsonDecode(response.body);
          message = errorBody['message'] ?? message;
        } catch (e) {
          developer.log(
            '[MED_REPO:getMedicationsByPatientId] Failed to parse error body: $e',
          );
          message =
              'Gagal memuat daftar obat. Respon server tidak dapat dibaca.';
        }
        developer.log(
          '[MED_REPO:getMedicationsByPatientId] Failed (${response.statusCode}): $message',
        );
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log('[MED_REPO:getMedicationsByPatientId] Error: $e');
      developer.log(
        '[MED_REPO:getMedicationsByPatientId] Stacktrace: $stackTrace',
      );
      return Left(
        "Terjadi kesalahan saat memuat daftar obat. Cek koneksi atau backend.",
      );
    }
  }

  // getTodaysMedicationSessions (Untuk Pasien/Keluarga: Jadwal Hari Ini)
  /// Mengambil daftar sesi konsumsi obat hari ini untuk pasien atau keluarga.
  Future<Either<String, TodaysMedicationSessionListResponseModel>>
  getTodaysMedicationSessions({
    required int? patientGlobalId,
    required String? patientUniqueId,
  }) async {
    try {
      final currentUser = await _getCurrentUserFromLocalStorage();
      if (currentUser == null) {
        return const Left("Data pengguna tidak ditemukan. Mohon login ulang.");
      }

      String endpoint;

      developer.log(
        '[MED_REPO:getTodaysMedicationSessions] User Role: ${currentUser.role}, Req Unique ID: $patientUniqueId, Req Global ID: $patientGlobalId',
      );

      if (currentUser.role?.toLowerCase() == 'pasien') {
        if (currentUser.idPasien == null) {
          return const Left(
            "ID Pasien tidak ditemukan di data pengguna. Mohon login ulang.",
          );
        }
        endpoint = 'medications/today';
        developer.log(
          '[MED_REPO:getTodaysMedicationSessions] Pasien Role - Final Endpoint: $endpoint',
        );
      } else if (currentUser.role?.toLowerCase() == 'keluarga') {
        if (patientUniqueId == null || patientUniqueId.isEmpty) {
          return const Left(
            'Untuk peran keluarga, Patient Unique ID harus disediakan untuk melihat jadwal obat.',
          );
        }
        endpoint = 'medications/patient/$patientUniqueId/today';
        developer.log(
          '[MED_REPO:getTodaysMedicationSessions] Keluarga Role - Final Endpoint: $endpoint',
        );
      } else {
        return const Left(
          "Peran pengguna tidak valid untuk mengambil sesi obat hari ini. Gunakan endpoint resep untuk dokter.",
        );
      }

      final response = await _httpClient.get(endpoint);

      developer.log(
        '[MED_REPO:getTodaysMedicationSessions] Response Status: ${response.statusCode}',
      );
      developer.log(
        '[MED_REPO:getTodaysMedicationSessions] Raw Response Body: ${response.body}',
      );

      if (response.statusCode == 200) {
        try {
          final responseModel =
              TodaysMedicationSessionListResponseModel.fromJson(response.body);
          developer.log(
            '[MED_REPO:getTodaysMedicationSessions] Success: ${responseModel.data.length} sessions loaded.',
          );
          return Right(responseModel);
        } catch (jsonError, st) {
          developer.log(
            '[MED_REPO:getTodaysMedicationSessions] JSON Parsing Error: $jsonError\n$st',
          );
          return const Left(
            "Gagal memproses data sesi obat dari server. Format data tidak valid.",
          );
        }
      } else {
        String message = 'Gagal memuat sesi obat hari ini.';
        try {
          final errorBody = jsonDecode(response.body);
          message = errorBody['message'] ?? message;
        } catch (e) {
          developer.log(
            '[MED_REPO:getTodaysMedicationSessions] Failed to parse error body: $e',
          );
          message =
              'Gagal memuat sesi obat hari ini. Respon server tidak dapat dibaca.';
        }
        developer.log(
          '[MED_REPO:getTodaysMedicationSessions] Failed (${response.statusCode}): $message',
        );
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log('[MED_REPO:getTodaysMedicationSessions] Error: $e');
      developer.log(
        '[MED_REPO:getTodaysMedicationSessions] Stacktrace: $stackTrace',
      );
      return Left(
        "Terjadi kesalahan saat memuat sesi obat hari ini. Cek koneksi atau backend.",
      );
    }
  }
}
