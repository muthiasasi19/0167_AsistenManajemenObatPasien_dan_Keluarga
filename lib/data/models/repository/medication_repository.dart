import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dartz/dartz.dart';
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

  //  FUNGSI getMedicationHistoryByPatientId
  Future<Either<String, MedicationHistoryResponseModel>>
  getMedicationHistoryByPatientId({
    required int? patientGlobalId,
    required String? patientUniqueId,
  }) async {
    try {
      final currentUser = await _getCurrentUserFromLocalStorage();
      if (currentUser == null) {
        return const Left("Data pengguna tidak ditemukan. Mohon login ulang.");
      }

      String endpoint;
      String targetPatientId;

      developer.log(
        'MedicationRepository: getMedicationHistoryByPatientId - Current User Role: ${currentUser.role}',
      );
      developer.log(
        'MedicationRepository: getMedicationHistoryByPatientId - patientUniqueId (input): $patientUniqueId',
      );
      developer.log(
        'MedicationRepository: getMedicationHistoryByPatientId - patientGlobalId (input): $patientGlobalId',
      );

      if (currentUser.role?.toLowerCase() == 'pasien') {
        if (currentUser.idPasien == null) {
          return const Left("ID Pasien tidak ditemukan di data pengguna.");
        }
        targetPatientId = currentUser.idPasien!;
        endpoint = 'medications/patient/$targetPatientId/history';
        developer.log(
          'MedicationRepository: (Pasien Role) Mengambil riwayat obat untuk ID Pasien: $targetPatientId',
        );
      } else if (currentUser.role?.toLowerCase() == 'dokter' ||
          currentUser.role?.toLowerCase() == 'keluarga') {
        if (patientUniqueId == null || patientUniqueId.isEmpty) {
          return const Left(
            'Silakan pilih pasien terlebih dahulu untuk melihat riwayat.',
          );
        }
        targetPatientId = patientUniqueId;
        endpoint = 'medications/patient/$targetPatientId/history';
        developer.log(
          'MedicationRepository: (${currentUser.role} Role) Mengambil riwayat obat untuk ID Pasien: $targetPatientId',
        );
      } else {
        return const Left(
          "Peran pengguna tidak valid untuk mengambil riwayat obat.",
        );
      }

      final response = await _httpClient.get(endpoint);

      developer.log(
        "Get Medication History Response Status code: ${response.statusCode}",
      );
      developer.log("Get Medication History Response body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final responseModel = MedicationHistoryResponseModel.fromJson(
            response.body,
          );
          developer.log(
            "Get Medication History Success: ${responseModel.data.length} history items loaded.",
          );
          return Right(responseModel);
        } catch (jsonError, st) {
          developer.log(
            "Get Medication History JSON Parsing Error: $jsonError\n$st",
          );
          return const Left(
            "Gagal memproses data riwayat obat dari server. Format data tidak valid.",
          );
        }
      } else {
        String message = 'Gagal memuat riwayat obat.';
        try {
          final errorBody = jsonDecode(response.body);
          message = errorBody['message'] ?? message;
        } catch (e) {
          developer.log(
            "Get Medication History Failed to parse error body: $e",
          );
          message =
              'Gagal memuat riwayat obat. Respon server tidak dapat dibaca.';
        }
        developer.log(
          "Get Medication History Failed (${response.statusCode}): $message",
        );
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log("Get Medication History Error: $e");
      developer.log("Get Medication History Stacktrace: $stackTrace");
      return Left(
        "Terjadi kesalahan saat memuat riwayat obat. Cek koneksi atau backend.",
      );
    }
  }

  //  FUNGSI addMedication
  Future<Either<String, SingleMedicationResponseModel>> addMedication(
    String patientUniqueId,
    AddMedicationRequestModel request,
  ) async {
    try {
      final doctorGlobalId = await _getDoctorGlobalId();
      if (doctorGlobalId == null) {
        return const Left("ID Dokter tidak ditemukan. Mohon login ulang.");
      }

      developer.log(
        "Adding Medication for Patient Unique ID: $patientUniqueId by Doctor ID: $doctorGlobalId",
      );

      final String endpoint = 'obat/$patientUniqueId';
      final String? token = await _httpClient.getToken();

      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      if (request.photoFile != null) {
        var uri = Uri.parse('${_httpClient.baseUrl}/api/$endpoint');
        var requestHttp = http.MultipartRequest('POST', uri);
        requestHttp.headers['Authorization'] = 'Bearer $token';

        // Tambah file foto
        requestHttp.files.add(
          await http.MultipartFile.fromPath(
            'photo',
            request.photoFile!.path,
            filename: request.photoFile!.path.split('/').last,
          ),
        );

        requestHttp.fields['medicationName'] = request.medicationName;
        requestHttp.fields['dosage'] = request.dosage;
        requestHttp.fields['schedule'] = json.encode(request.schedule.toMap());
        requestHttp.fields['description'] = request.description ?? '';

        var streamedResponse = await requestHttp.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          developer.log(
            'Medication added successfully with photo: ${response.body}',
          );
          return Right(SingleMedicationResponseModel.fromJson(response.body));
        } else {
          developer.log(
            'Failed to add medication with photo: ${response.statusCode} ${response.body}',
          );
          String message = 'Gagal menambahkan obat dengan foto.';
          try {
            final errorBody = jsonDecode(response.body);
            message = errorBody['message'] ?? message;
          } catch (e) {}
          return Left(message);
        }
      } else {
        developer.log(
          "Medication Request Body (no photo): ${jsonEncode(request.toMap())}",
        );
        final response = await _httpClient.postWithToken(
          endpoint,
          request.toMap(),
        );

        developer.log(
          "Add Medication Response Status code: ${response.statusCode}",
        );
        developer.log("Add Medication Response body: ${response.body}");

        if (response.statusCode == 201) {
          try {
            final responseModel = SingleMedicationResponseModel.fromJson(
              response.body,
            );
            developer.log("Add Medication Success: ${responseModel.message}");
            return Right(responseModel);
          } catch (jsonError, st) {
            developer.log("Add Medication JSON Parsing Error: $jsonError\n$st");
            return const Left(
              "Gagal memproses data obat yang ditambahkan dari server. Format data tidak valid.",
            );
          }
        } else {
          String message = 'Gagal menambahkan obat.';
          try {
            final errorBody = jsonDecode(response.body);
            message = errorBody['message'] ?? message;
          } catch (e) {
            developer.log("Add Medication Failed to parse error body: $e");
            message =
                'Gagal menambahkan obat. Respon server tidak dapat dibaca.';
          }
          developer.log(
            "Add Medication Failed (${response.statusCode}): $message",
          );
          return Left(message);
        }
      }
    } catch (e, stackTrace) {
      developer.log("Add Medication Error: $e");
      developer.log("Add Medication Stacktrace: $stackTrace");
      return Left(
        "Terjadi kesalahan saat menambahkan obat. Cek koneksi atau backend: $e",
      );
    }
  }

  //  FUNGSI updateMedication
  Future<Either<String, SingleMedicationResponseModel>> updateMedication(
    int medicationId,
    UpdateMedicationRequestModel request,
  ) async {
    try {
      final doctorGlobalId = await _getDoctorGlobalId();
      if (doctorGlobalId == null) {
        return const Left("ID Dokter tidak ditemukan. Mohon login ulang.");
      }

      developer.log(
        "Updating Medication ID: $medicationId by Doctor ID: $doctorGlobalId",
      );
      developer.log(
        "Update Medication Request Body: ${jsonEncode(request.toMap())}",
      );

      final response = await _httpClient.put(
        'obat/$medicationId',
        request.toMap(),
      );

      developer.log(
        "Update Medication Response Status code: ${response.statusCode}",
      );
      developer.log("Update Medication Response body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final responseModel = SingleMedicationResponseModel.fromJson(
            response.body,
          );
          developer.log("Update Medication Success: ${responseModel.message}");
          return Right(responseModel);
        } catch (jsonError, st) {
          developer.log(
            "Update Medication JSON Parsing Error: $jsonError\n$st",
          );
          return const Left(
            "Gagal memproses data obat yang diperbarui dari server. Format data tidak valid.",
          );
        }
      } else {
        String message = 'Gagal memperbarui obat.';
        try {
          final errorBody = jsonDecode(response.body);
          message = errorBody['message'] ?? message;
        } catch (e) {
          developer.log("Update Medication Failed to parse error body: $e");
          message = 'Gagal memperbarui obat. Respon server tidak dapat dibaca.';
        }
        developer.log(
          "Update Medication Failed (${response.statusCode}): $message",
        );
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log("Update Medication Error: $e");
      developer.log("Update Medication Stacktrace: $stackTrace");
      return Left(
        "Terjadi kesalahan saat memperbarui obat. Cek koneksi atau backend.",
      );
    }
  }

  //  FUNGSI deleteMedication
  Future<Either<String, String>> deleteMedication(int medicationId) async {
    try {
      final doctorGlobalId = await _getDoctorGlobalId();
      if (doctorGlobalId == null) {
        return const Left("ID Dokter tidak ditemukan. Mohon login ulang.");
      }

      developer.log(
        "Deleting Medication ID: $medicationId by Doctor ID: $doctorGlobalId",
      );

      final response = await _httpClient.delete('obat/$medicationId');

      developer.log(
        "Delete Medication Response Status code: ${response.statusCode}",
      );
      developer.log("Delete Medication Response body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final responseBody = jsonDecode(response.body);
          final message = responseBody['message'] ?? 'Obat berhasil dihapus.';
          developer.log("Delete Medication Success: $message");
          return Right(message);
        } catch (jsonError, st) {
          developer.log(
            "Delete Medication JSON Parsing Error: $jsonError\n$st",
          );
          return const Left(
            "Gagal memproses respons penghapusan obat dari server. Format data tidak valid.",
          );
        }
      } else {
        String message = 'Gagal menghapus obat.';
        try {
          final errorBody = jsonDecode(response.body);
          message = errorBody['message'] ?? message;
        } catch (e) {
          developer.log("Delete Medication Failed to parse error body: $e");
          message = 'Gagal menghapus obat. Respon server tidak dapat dibaca.';
        }
        developer.log(
          "Delete Medication Failed (${response.statusCode}): $message",
        );
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log("Delete Medication Error: $e");
      developer.log("Delete Medication Stacktrace: $stackTrace");
      return Left(
        "Terjadi kesalahan saat menghapus obat. Cek koneksi atau backend.",
      );
    }
  }

  // FUNGSI markMedicationConsumption
  Future<Either<String, String>> markMedicationConsumption(
    int medicationGlobalId,
    String status,
    String? scheduledTime,
    String? notes,
  ) async {
    try {
      final currentUser = await _getCurrentUserFromLocalStorage();
      if (currentUser == null) {
        return const Left("Data pengguna tidak ditemukan. Mohon login ulang.");
      }

      developer.log(
        "Marking consumption for Medication ID: $medicationGlobalId with status: $status, scheduledTime: ${scheduledTime ?? 'N/A'}",
      );

      final Map<String, dynamic> body = {'status': status};

      if (scheduledTime != null && scheduledTime.isNotEmpty) {
        body['scheduledTime'] = scheduledTime;
      }

      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      final response = await _httpClient.postWithToken(
        'riwayat-konsumsi/$medicationGlobalId',
        body,
      );

      developer.log(
        "Mark Consumption Response Status code: ${response.statusCode}",
      );
      developer.log("Mark Consumption Response body: ${response.body}");
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseBody = jsonDecode(response.body);
          // Mengembalikan pesan sukses dari backend
          return Right(
            responseBody['message'] ?? 'Status konsumsi berhasil diperbarui.',
          );
        } catch (jsonError, st) {
          developer.log("Mark Consumption JSON Parsing Error: $jsonError\n$st");
          return const Left(
            "Gagal memproses respons status konsumsi dari server. Format data tidak valid.",
          );
        }
      } else {
        String message = 'Gagal menandai konsumsi obat.';
        try {
          final errorBody = jsonDecode(response.body);
          message = errorBody['message'] ?? message;
        } catch (e) {
          developer.log("Mark Consumption Failed to parse error body: $e");
          message =
              'Gagal menandai konsumsi obat. Respon server tidak dapat dibaca.';
        }
        developer.log(
          "Mark Consumption Response Failed (${response.statusCode}): $message",
        );
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log("Mark Consumption Error: $e");
      developer.log("Mark Consumption Stacktrace: $stackTrace");
      return Left('Terjadi kesalahan saat menandai konsumsi: $e');
    }
  }
}
