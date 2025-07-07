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
}
