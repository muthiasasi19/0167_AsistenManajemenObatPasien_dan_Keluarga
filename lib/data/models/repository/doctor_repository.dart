// lib/data/repository/doctor_repository.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manajemen_obat/service/service_http_client.dart';
import 'package:manajemen_obat/data/models/response/doctor_response_model.dart';
import 'package:manajemen_obat/data/models/response/patient_response_model.dart';
import 'package:manajemen_obat/data/models/response/login_response_model.dart'; // Import User model

class DoctorRepository {
  final ServiceHttpClient _httpClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  DoctorRepository(this._httpClient);

  // Helper function to get the current user data from local storage
  // This is crucial for retrieving the doctor's global ID and other profile data.
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

  /// @desc Get the profile data for the logged-in doctor
  /// @route GET /api/doctor/profile (assuming this endpoint exists and uses token)
  Future<Either<String, DoctorData>> getDoctorProfile() async {
    try {
      final currentUser = await _getCurrentUserFromLocalStorage();
      if (currentUser == null || currentUser.role?.toLowerCase() != 'dokter') {
        return const Left(
          "Anda tidak memiliki akses sebagai dokter atau data pengguna tidak ditemukan. Mohon login ulang.",
        );
      }

      developer.log("DoctorRepository: Mengambil data profil dokter...");
      // Assuming your backend has an endpoint like /api/doctor/profile that returns the doctor's data based on the token.
      final response = await _httpClient.get('doctor/profile');

      developer.log(
        "DoctorRepository - getDoctorProfile: Status Code: ${response.statusCode}",
      );
      developer.log(
        "DoctorRepository - getDoctorProfile: Body: ${response.body}",
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final dynamic data = responseBody['data'];
        if (data != null) {
          final doctorData = DoctorData.fromJson(data);
          developer.log(
            "DoctorRepository - getDoctorProfile: Berhasil memuat profil dokter: ${doctorData.name}",
          );
          return Right(doctorData);
        } else {
          return const Left("Data profil dokter tidak ditemukan.");
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Gagal memuat profil dokter.';
        developer.log(
          "DoctorRepository - getDoctorProfile: Gagal (${response.statusCode}): $message",
        );
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log(
        "DoctorRepository - getDoctorProfile Error: $e\n$stackTrace",
      );
      return const Left("Terjadi kesalahan saat memuat profil dokter.");
    }
  }

  /// @desc Get a list of patients connected to the logged-in doctor
  /// @route GET /api/doctor/my-connected-patients (assuming this endpoint exists and uses token)
  Future<Either<String, List<Patient>>> getConnectedPatients() async {
    try {
      final currentUser = await _getCurrentUserFromLocalStorage();
      if (currentUser == null || currentUser.role?.toLowerCase() != 'dokter') {
        return const Left(
          "Anda tidak memiliki akses sebagai dokter atau data pengguna tidak ditemukan. Mohon login ulang.",
        );
      }

      developer.log(
        "DoctorRepository: Mengambil daftar pasien terhubung untuk dokter...",
      );
      // Assuming endpoint is 'doctor/my-connected-patients' and token handles doctor identification
      final response = await _httpClient.get('doctor/my-connected-patients');

      developer.log(
        "DoctorRepository - getConnectedPatients: Status Code: ${response.statusCode}",
      );
      developer.log(
        "DoctorRepository - getConnectedPatients: Body: ${response.body}",
      );

      if (response.statusCode == 200) {
        final responseModel = PatientsListResponseModel.fromJson(response.body);
        developer.log(
          "DoctorRepository - getConnectedPatients: Berhasil, ${responseModel.data.length} pasien terhubung dimuat.",
        );
        return Right(responseModel.data);
      } else {
        final errorBody = jsonDecode(response.body);
        final message =
            errorBody['message'] ?? 'Gagal memuat daftar pasien terhubung.';
        developer.log(
          "DoctorRepository - getConnectedPatients: Gagal (${response.statusCode}): $message",
        );
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log(
        "DoctorRepository - getConnectedPatients Error: $e\n$stackTrace",
      );
      return const Left(
        "Terjadi kesalahan saat memuat daftar pasien terhubung.",
      );
    }
  }

  /// @desc Connect a patient to the logged-in doctor
  /// @route POST /api/doctor/connect-patient
  /// This method is already present in PatientRepository, but duplicated here for Doctor's specific context if needed.
  /// It's better to keep it where it is, or move it to a shared repository if both roles connect.
  /// For now, I'll assume PatientRepository's connectPatient handles the backend call correctly for doctor's use case.
  /// However, for the sake of explicit Doctor features, I'll add a wrapper here that leverages patientUniqueId and the logged-in doctor's global ID.
  Future<Either<String, String>> connectPatient(String patientUniqueId) async {
    try {
      final currentUser = await _getCurrentUserFromLocalStorage();
      if (currentUser == null ||
          currentUser.role?.toLowerCase() != 'dokter' ||
          currentUser.idDokter == null) {
        return const Left("Data dokter tidak ditemukan. Mohon login ulang.");
      }

      developer.log(
        "DoctorRepository: Menghubungkan pasien '$patientUniqueId' dengan dokter '${currentUser.idDokter}'",
      );

      // Assuming backend expects: { "patientUniqueId": "...", "doctorId": "..." }
      // Or it might just expect patientUniqueId and takes doctorId from the token.
      // Based on your patient_repository.dart, it sends both: {'patientUniqueId': patientUniqueId, 'doctorId': doctorId}
      final response = await _httpClient.postWithToken(
        'doctor/connect-patient',
        {'patientUniqueId': patientUniqueId, 'doctorId': currentUser.idDokter},
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final message =
            responseBody['message'] ?? 'Pasien berhasil dihubungkan.';
        developer.log("DoctorRepository - connectPatient: Berhasil: $message");
        return Right(message);
      } else {
        final message =
            responseBody['message'] ?? 'Gagal menghubungkan pasien.';
        developer.log(
          "DoctorRepository - connectPatient: Gagal (${response.statusCode}): $message",
        );
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log("DoctorRepository - connectPatient Error: $e\n$stackTrace");
      return Left("Terjadi kesalahan saat menghubungkan pasien.");
    }
  }

  /// @desc Disconnect a patient from the logged-in doctor
  /// @route DELETE /api/doctor/disconnect-patient/:patientUniqueId
  Future<Either<String, String>> disconnectPatient(
    String patientUniqueId,
  ) async {
    try {
      final currentUser = await _getCurrentUserFromLocalStorage();
      if (currentUser == null ||
          currentUser.role?.toLowerCase() != 'dokter' ||
          currentUser.idDokter == null) {
        return const Left("Data dokter tidak ditemukan. Mohon login ulang.");
      }

      developer.log(
        "DoctorRepository: Memutuskan koneksi pasien '$patientUniqueId' dari dokter '${currentUser.idDokter}'",
      );

      final response = await _httpClient.delete(
        'doctor/disconnect-patient/$patientUniqueId',
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final message =
            responseBody['message'] ?? 'Koneksi pasien berhasil diputuskan.';
        developer.log(
          "DoctorRepository - disconnectPatient: Berhasil: $message",
        );
        return Right(message);
      } else {
        final message =
            responseBody['message'] ?? 'Gagal memutuskan koneksi pasien.';
        developer.log(
          "DoctorRepository - disconnectPatient: Gagal (${response.statusCode}): $message",
        );
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log(
        "DoctorRepository - disconnectPatient Error: $e\n$stackTrace",
      );
      return Left("Terjadi kesalahan saat memutuskan koneksi pasien.");
    }
  }

  // Note: CRUD Medication functions (addMedication, updateMedication, deleteMedication, getMedicationsByPatientId, getMedicationHistoryByPatientId)
  // are already handled by MedicationRepository. DoctorBloc will directly call MedicationRepository for these.
}
