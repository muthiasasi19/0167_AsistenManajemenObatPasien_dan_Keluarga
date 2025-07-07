import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manajemen_obat/service/service_http_client.dart';
import 'package:manajemen_obat/data/models/response/patient_response_model.dart';
import 'package:manajemen_obat/data/models/response/patient_search_result_model.dart';
import 'package:manajemen_obat/data/models/response/doctor_response_model.dart';

class PatientRepository {
  final ServiceHttpClient _httpClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  PatientRepository(this._httpClient);

  Future<String?> _getDoctorIdFromLocalStorage() async {
    final userDataString = await _secureStorage.read(key: 'userData');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      return userData['id_dokter']?.toString();
    }
    return null;
  }

  // Mendapatkan Dokter Terhubung untuk Pasien ---
  Future<Either<String, DoctorData>> getConnectedDoctor(
    String patientUniqueId,
  ) async {
    try {
      developer.log(
        "PatientRepository: Mengambil data dokter terhubung untuk pasien (dari token)",
      );

      // Backend API /api/patient/connected-doctor akan mengambil id_pasien dari token
      final response = await _httpClient.get('patient/connected-doctor');

      developer.log(
        "PatientRepository - getConnectedDoctor: Status Code: ${response.statusCode}",
      );
      developer.log(
        "PatientRepository - getConnectedDoctor: Body: ${response.body}",
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final dynamic data =
            responseBody['data']; // Bisa null kalau tidak ada dokter terhubung

        if (data != null) {
          final doctor = DoctorData.fromJson(data);
          developer.log(
            "PatientRepository - getConnectedDoctor: Berhasil, dokter ${doctor.name} ditemukan.",
          );
          return Right(doctor);
        } else {
          developer.log(
            "PatientRepository - getConnectedDoctor: Pasien belum terhubung dengan dokter manapun (data: null).",
          );
          return const Left('Pasien belum terhubung dengan dokter manapun.');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final message =
            errorBody['message'] ?? 'Gagal memuat dokter terhubung.';
        developer.log(
          "PatientRepository - getConnectedDoctor: Gagal (${response.statusCode}): $message",
        );
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log(
        "PatientRepository - getConnectedDoctor Error: $e\n$stackTrace",
      );
      return const Left("Terjadi kesalahan saat memuat dokter terhubung.");
    }
  }

  Future<Either<String, PatientsListResponseModel>> getPatients() async {
    try {
      final doctorId = await _getDoctorIdFromLocalStorage();
      if (doctorId == null) {
        developer.log(
          "PatientRepository: Gagal getPatients, ID Dokter tidak ditemukan.",
        );
        return const Left("ID Dokter tidak ditemukan. Mohon login ulang.");
      }
      developer.log(
        "PatientRepository: Mengambil daftar pasien untuk dokter ID: $doctorId",
      );
      final response = await _httpClient.get(
        'doctor/patients?doctorId=$doctorId',
      );

      developer.log(
        "PatientRepository - getPatients: Status Code: ${response.statusCode}",
      );
      developer.log("PatientRepository - getPatients: Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseModel = PatientsListResponseModel.fromJson(response.body);
        developer.log(
          "PatientRepository - getPatients: Berhasil, ${responseModel.data.length} pasien dimuat.",
        );
        return Right(responseModel);
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Gagal memuat daftar pasien.';
        developer.log(
          "PatientRepository - getPatients: Gagal (${response.statusCode}): $message",
        );
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log("PatientRepository - getPatients Error: $e\n$stackTrace");
      return const Left("Terjadi kesalahan saat memuat daftar pasien.");
    }
  }

  Future<Either<String, SinglePatientResponseModel>> connectPatient(
    String patientUniqueId,
  ) async {
    try {
      final doctorId = await _getDoctorIdFromLocalStorage();
      if (doctorId == null) {
        developer.log(
          "PatientRepository: Gagal connectPatient, ID Dokter tidak ditemukan.",
        );
        return const Left("ID Dokter tidak ditemukan. Mohon login ulang.");
      }
      developer.log(
        "PatientRepository: Menghubungkan pasien: $patientUniqueId dengan dokter: $doctorId",
      );
      final response = await _httpClient.postWithToken(
        'doctor/connect-patient',
        {'patientUniqueId': patientUniqueId, 'doctorId': doctorId},
      );

      developer.log(
        "PatientRepository - connectPatient: Status Code: ${response.statusCode}",
      );
      developer.log(
        "PatientRepository - connectPatient: Body: ${response.body}",
      );

      if (response.statusCode == 201) {
        final responseModel = SinglePatientResponseModel.fromJson(
          response.body,
        );
        developer.log(
          "PatientRepository - connectPatient: Berhasil, ${responseModel.message}",
        );
        return Right(responseModel);
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Gagal menghubungkan pasien.';
        developer.log(
          "PatientRepository - connectPatient: Gagal (${response.statusCode}): $message",
        );
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log(
        "PatientRepository - connectPatient Error: $e\n$stackTrace",
      );
      return const Left("Terjadi kesalahan saat menghubungkan pasien.");
    }
  }
}
