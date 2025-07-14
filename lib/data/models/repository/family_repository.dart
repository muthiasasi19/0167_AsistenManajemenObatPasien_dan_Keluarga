import 'dart:convert';
import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manajemen_obat/data/models/response/family_response_model.dart';
import 'package:manajemen_obat/service/Storage_Helper.dart';
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
    FamilyConnectRequestModel request, // Ini model REQUEST yang benar
  ) async {
    try {
      log(
        "FamilyRepository: Mengirim request koneksi keluarga ke pasien: ${request.patientUniqueId}",
      );
      // request.toMap() sekarang diharapkan berisi familyId dan familyGlobalId
      // karena sudah ditambahkan ke FamilyConnectRequestModel di Bloc.
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

  /// @desc Mendapatkan daftar pasien yang terhubung dengan keluarga
  /// @route GET /api/family/my-connected-patients
  Future<Either<String, List<FamilyConnectedPatientData>>>
  getConnectedPatientsForFamily({int? familyGlobalId}) async {
    try {
      final resolvedFamilyGlobalId =
          familyGlobalId ?? await _getFamilyGlobalIdFromLocalStorage();

      if (resolvedFamilyGlobalId == null) {
        log(
          "FamilyRepository: Gagal getConnectedPatientsForFamily, ID Keluarga tidak ditemukan (baik dari parameter maupun local storage).",
        );
        return const Left("ID Keluarga tidak ditemukan. Mohon login ulang.");
      }
      log(
        "FamilyRepository: Mengambil daftar pasien terhubung untuk keluarga ID: $resolvedFamilyGlobalId",
      );

      final response = await _httpClient.get('family/my-connected-patients');

      log(
        "FamilyRepository - getConnectedPatientsForFamily: Status Code: ${response.statusCode}",
      );
      log(
        "FamilyRepository - getConnectedPatientsForFamily: Body: ${response.body}",
      );

      if (response.statusCode == 200) {
        final responseModel = FamilyConnectedPatientResponseModel.fromJson(
          response.body,
        );
        log(
          "FamilyRepository - getConnectedPatientsForFamily: Berhasil, ${responseModel.data.length} pasien terhubung dimuat.",
        );
        return Right(responseModel.data);
      } else {
        final errorBody = jsonDecode(response.body);
        final message =
            errorBody['message'] ?? 'Gagal memuat daftar pasien terhubung.';
        log(
          "FamilyRepository - getConnectedPatientsForFamily: Gagal (${response.statusCode}): $message",
        );
        return Left(message);
      }
    } catch (e, stackTrace) {
      log(
        "FamilyRepository - getConnectedPatientsForFamily Error: $e\n$stackTrace",
      );
      return Left("Terjadi kesalahan saat memuat daftar pasien terhubung.");
    }
  }

  /// @desc Mendapatkan daftar obat untuk pasien tertentu yang terhubung (oleh keluarga)
  /// @route GET /api/family/patients/:patientGlobalId/medications
  Future<Either<String, List<Medication>>> getPatientMedicationsForFamily(
    int patientGlobalId,
  ) async {
    try {
      final familyGlobalId = await _getFamilyGlobalIdFromLocalStorage();
      if (familyGlobalId == null) {
        return const Left("ID Keluarga tidak ditemukan. Mohon login ulang.");
      }
      log(
        "FamilyRepository: Mengambil obat pasien ID: $patientGlobalId untuk keluarga ID: $familyGlobalId",
      );

      final response = await _httpClient.get(
        'family/patients/$patientGlobalId/medications',
      );

      log(
        "FamilyRepository - getPatientMedicationsForFamily: Status Code: ${response.statusCode}",
      );
      log(
        "FamilyRepository - getPatientMedicationsForFamily: Body: ${response.body}",
      );

      if (response.statusCode == 200) {
        final responseModel = MedicationsListResponseModel.fromJson(
          response.body,
        );
        return Right(responseModel.data);
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Gagal memuat obat pasien.';
        return Left(message);
      }
    } catch (e, stackTrace) {
      log(
        "FamilyRepository - getPatientMedicationsForFamily Error: $e\n$stackTrace",
      );
      return Left("Terjadi kesalahan saat memuat obat pasien.");
    }
  }

  /// @desc Mendapatkan riwayat konsumsi obat untuk pasien tertentu yang terhubung (oleh keluarga)
  /// @route GET /api/family/patients/:patientGlobalId/medication-history
  Future<Either<String, List<MedicationHistoryData>>>
  getPatientMedicationHistoryForFamily(int patientGlobalId) async {
    try {
      final familyGlobalId = await _getFamilyGlobalIdFromLocalStorage();
      if (familyGlobalId == null) {
        return const Left("ID Keluarga tidak ditemukan. Mohon login ulang.");
      }
      log(
        "FamilyRepository: Mengambil riwayat konsumsi pasien ID: $patientGlobalId untuk keluarga ID: $familyGlobalId",
      );

      final response = await _httpClient.get(
        'family/patients/$patientGlobalId/medication-history',
      );

      log(
        "FamilyRepository - getPatientMedicationHistoryForFamily: Status Code: ${response.statusCode}",
      );
      log(
        "FamilyRepository - getPatientMedicationHistoryForFamily: Body: ${response.body}",
      );

      if (response.statusCode == 200) {
        final responseModel = MedicationHistoryResponseModel.fromJson(
          response.body,
        );
        return Right(responseModel.data);
      } else {
        final errorBody = jsonDecode(response.body);
        final message =
            errorBody['message'] ??
            'Gagal memuat riwayat konsumsi obat pasien.';
        return Left(message);
      }
    } catch (e, stackTrace) {
      log(
        "FamilyRepository - getPatientMedicationHistoryForFamily Error: $e\n$stackTrace",
      );
      return Left(
        "Terjadi kesalahan saat memuat riwayat konsumsi obat pasien.",
      );
    }
  }

  /// @desc Mendapatkan lokasi terakhir pasien yang terhubung (oleh keluarga)
  /// @route GET /api/family/patients/:patientGlobalId/location
  Future<Either<String, PatientLocationData>> getPatientLastLocationForFamily(
    int patientGlobalId,
  ) async {
    try {
      final familyGlobalId = await _getFamilyGlobalIdFromLocalStorage();
      if (familyGlobalId == null) {
        return const Left("ID Keluarga tidak ditemukan. Mohon login ulang.");
      }
      log(
        "FamilyRepository: Mengambil lokasi pasien ID: $patientGlobalId untuk keluarga ID: $familyGlobalId",
      );

      final response = await _httpClient.get(
        'family/patients/$patientGlobalId/location',
      );

      log(
        "FamilyRepository - getPatientLastLocationForFamily: Status Code: ${response.statusCode}",
      );
      log(
        "FamilyRepository - getPatientLastLocationForFamily: Body: ${response.body}",
      );

      if (response.statusCode == 200) {
        final responseModel = PatientLocationResponseModel.fromJson(
          response.body,
        );
        if (responseModel.data != null) {
          return Right(responseModel.data!);
        } else {
          return Left(responseModel.message ?? 'Lokasi pasien belum tersedia.');
        }
      } else if (response.statusCode == 404) {
        // Menangani 404 khusus untuk "Lokasi belum tersedia"
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Lokasi pasien belum tersedia.';
        return Left(message);
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Gagal memuat lokasi pasien.';
        return Left(message);
      }
    } catch (e, stackTrace) {
      log(
        "FamilyRepository - getPatientLastLocationForFamily Error: $e\n$stackTrace",
      );
      return Left("Terjadi kesalahan saat memuat lokasi pasien.");
    }
  }

  //Fungsi family profil
  Future<FamilyResponseModel> getFamilyProfile() async {
    try {
      final response = await _httpClient.get(
        '/family/profile', // Endpoint untuk profil keluarga
      );
      return FamilyResponseModel.fromJson(response.body);
    } catch (e) {
      print('Error fetching family profile: $e'); // Untuk debugging
      rethrow;
    }
  }
}
