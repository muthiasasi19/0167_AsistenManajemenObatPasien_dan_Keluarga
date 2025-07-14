import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manajemen_obat/service/service_http_client.dart';
import 'package:manajemen_obat/data/models/request/notification/add_notification_schedule_request_model.dart';
import 'package:manajemen_obat/data/models/request/notification/update_notification_schedule_request_model.dart';
import 'package:manajemen_obat/data/models/response/notification_schedule_response_model.dart';
import 'package:manajemen_obat/data/models/response/login_response_model.dart'; // Untuk mendapatkan data user

class NotificationRepository {
  final ServiceHttpClient _httpClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  NotificationRepository(this._httpClient);

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

  /// Menambah jadwal notifikasi baru (oleh Dokter).
  Future<Either<String, NotificationScheduleData>> addNotificationSchedule(
    AddNotificationScheduleRequestModel request,
  ) async {
    try {
      final currentUser = await _getCurrentUserFromLocalStorage();
      if (currentUser == null || currentUser.role?.toLowerCase() != 'dokter') {
        return const Left(
          "Tidak diotorisasi: Hanya dokter yang dapat menambah jadwal notifikasi.",
        );
      }

      developer.log(
        "AddNotificationSchedule Request Body: ${request.toJson()}",
      );

      final response = await _httpClient.postWithToken(
        'notifications/schedules',
        request.toMap(),
      );

      developer.log(
        "Add Notification Schedule Response Status: ${response.statusCode}",
      );
      developer.log(
        "Add Notification Schedule Response Body: ${response.body}",
      );

      if (response.statusCode == 201) {
        try {
          final responseBody = json.decode(response.body);
          final NotificationScheduleData newSchedule =
              NotificationScheduleData.fromMap(responseBody['data']);
          return Right(newSchedule);
        } catch (jsonError, st) {
          developer.log(
            "Add Notification Schedule JSON Parsing Error: $jsonError\n$st",
          );
          return const Left(
            "Gagal memproses data jadwal notifikasi dari server.",
          );
        }
      } else {
        String message = 'Gagal menambah jadwal notifikasi.';
        try {
          final errorBody = json.decode(response.body);
          message = errorBody['message'] ?? message;
        } catch (e) {
          developer.log("Failed to parse error body: $e");
        }
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log("Error adding notification schedule: $e\n$stackTrace");
      return Left("Terjadi kesalahan saat menambah jadwal notifikasi: $e");
    }
  }

  /// Memperbarui jadwal notifikasi yang sudah ada (oleh Dokter).
  Future<Either<String, NotificationScheduleData>> updateNotificationSchedule(
    int scheduleId,
    UpdateNotificationScheduleRequestModel request,
  ) async {
    try {
      final currentUser = await _getCurrentUserFromLocalStorage();
      if (currentUser == null || currentUser.role?.toLowerCase() != 'dokter') {
        return const Left(
          "Tidak diotorisasi: Hanya dokter yang dapat memperbarui jadwal notifikasi.",
        );
      }

      developer.log(
        "UpdateNotificationSchedule Request Body: ${request.toJson()}",
      );

      final response = await _httpClient.put(
        'notifications/schedules/$scheduleId',
        request.toMap(),
      );

      developer.log(
        "Update Notification Schedule Response Status: ${response.statusCode}",
      );
      developer.log(
        "Update Notification Schedule Response Body: ${response.body}",
      );

      if (response.statusCode == 200) {
        try {
          final responseBody = json.decode(response.body);
          final NotificationScheduleData updatedSchedule =
              NotificationScheduleData.fromMap(responseBody['data']);
          return Right(updatedSchedule);
        } catch (jsonError, st) {
          developer.log(
            "Update Notification Schedule JSON Parsing Error: $jsonError\n$st",
          );
          return const Left(
            "Gagal memproses data jadwal notifikasi dari server.",
          );
        }
      } else {
        String message = 'Gagal memperbarui jadwal notifikasi.';
        try {
          final errorBody = json.decode(response.body);
          message = errorBody['message'] ?? message;
        } catch (e) {
          developer.log("Failed to parse error body: $e");
        }
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log("Error updating notification schedule: $e\n$stackTrace");
      return Left("Terjadi kesalahan saat memperbarui jadwal notifikasi: $e");
    }
  }

  /// Mengambil jadwal notifikasi untuk obat dan pasien tertentu (oleh Dokter).
  Future<Either<String, List<NotificationScheduleData>>>
  fetchNotificationSchedulesForMedicationAndPatient({
    required int medicationGlobalId,
    required int patientGlobalId,
  }) async {
    try {
      final currentUser = await _getCurrentUserFromLocalStorage();
      if (currentUser == null || currentUser.role?.toLowerCase() != 'dokter') {
        return const Left(
          "Tidak diotorisasi: Hanya dokter yang dapat melihat jadwal notifikasi.",
        );
      }

      final response = await _httpClient.get(
        'notifications/schedules/medication/$medicationGlobalId/patient/$patientGlobalId',
      );

      developer.log(
        "Fetch Notification Schedules for Med/Patient Response Status: ${response.statusCode}",
      );
      developer.log(
        "Fetch Notification Schedules for Med/Patient Response Body: ${response.body}",
      );

      if (response.statusCode == 200) {
        try {
          final responseModel = NotificationScheduleResponseModel.fromJson(
            response.body,
          );
          return Right(responseModel.data);
        } catch (jsonError, st) {
          developer.log(
            "Fetch Notification Schedules for Med/Patient JSON Parsing Error: $jsonError\n$st",
          );
          return const Left(
            "Gagal memproses data jadwal notifikasi dari server.",
          );
        }
      } else {
        String message = 'Gagal memuat jadwal notifikasi.';
        try {
          final errorBody = json.decode(response.body);
          message = errorBody['message'] ?? message;
        } catch (e) {
          developer.log("Failed to parse error body: $e");
        }
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log(
        "Error fetching notification schedules for medication and patient: $e\n$stackTrace",
      );
      return Left("Terjadi kesalahan saat memuat jadwal notifikasi: $e");
    }
  }

  /// Mengambil semua jadwal notifikasi yang relevan untuk pasien/keluarga yang login.
  Future<Either<String, List<NotificationScheduleData>>>
  fetchMyNotificationSchedules() async {
    try {
      final currentUser = await _getCurrentUserFromLocalStorage();
      if (currentUser == null ||
          (currentUser.role?.toLowerCase() != 'pasien' &&
              currentUser.role?.toLowerCase() != 'keluarga')) {
        return const Left(
          "Tidak diotorisasi: Hanya pasien atau keluarga yang dapat melihat jadwal notifikasi mereka.",
        );
      }

      final response = await _httpClient.get('notifications/schedules/user');

      developer.log(
        "Fetch My Notification Schedules Response Status: ${response.statusCode}",
      );
      developer.log(
        "Fetch My Notification Schedules Response Body: ${response.body}",
      );

      if (response.statusCode == 200) {
        try {
          final responseModel = NotificationScheduleResponseModel.fromJson(
            response.body,
          );
          return Right(responseModel.data);
        } catch (jsonError, st) {
          developer.log(
            "Fetch My Notification Schedules JSON Parsing Error: $jsonError\n$st",
          );
          return const Left(
            "Gagal memproses data jadwal notifikasi dari server.",
          );
        }
      } else {
        String message = 'Gagal memuat jadwal notifikasi Anda.';
        try {
          final errorBody = json.decode(response.body);
          message = errorBody['message'] ?? message;
        } catch (e) {
          developer.log("Failed to parse error body: $e");
        }
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log(
        "Error fetching my notification schedules: $e\n$stackTrace",
      );
      return Left("Terjadi kesalahan saat memuat jadwal notifikasi Anda: $e");
    }
  }

  /// Menghapus jadwal notifikasi (oleh Dokter).
  Future<Either<String, String>> deleteNotificationSchedule(
    int scheduleId,
  ) async {
    try {
      final currentUser = await _getCurrentUserFromLocalStorage();
      if (currentUser == null || currentUser.role?.toLowerCase() != 'dokter') {
        return const Left(
          "Tidak diotorisasi: Hanya dokter yang dapat menghapus jadwal notifikasi.",
        );
      }

      final response = await _httpClient.delete(
        'notifications/schedules/$scheduleId',
      );

      developer.log(
        "Delete Notification Schedule Response Status: ${response.statusCode}",
      );
      developer.log(
        "Delete Notification Schedule Response Body: ${response.body}",
      );

      if (response.statusCode == 200) {
        try {
          final responseBody = json.decode(response.body);
          final message =
              responseBody['message'] ?? 'Jadwal notifikasi berhasil dihapus.';
          return Right(message);
        } catch (jsonError, st) {
          developer.log(
            "Delete Notification Schedule JSON Parsing Error: $jsonError\n$st",
          );
          return const Left(
            "Gagal memproses respons penghapusan jadwal notifikasi dari server.",
          );
        }
      } else {
        String message = 'Gagal menghapus jadwal notifikasi.';
        try {
          final errorBody = json.decode(response.body);
          message = errorBody['message'] ?? message;
        } catch (e) {
          developer.log("Failed to parse error body: $e");
        }
        return Left(message);
      }
    } catch (e, stackTrace) {
      developer.log("Error deleting notification schedule: $e\n$stackTrace");
      return Left("Terjadi kesalahan saat menghapus jadwal notifikasi: $e");
    }
  }
}
