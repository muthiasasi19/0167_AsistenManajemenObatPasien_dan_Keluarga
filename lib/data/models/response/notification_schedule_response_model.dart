import 'dart:convert';

class NotificationScheduleResponseModel {
  final String message;
  final List<NotificationScheduleData> data;

  NotificationScheduleResponseModel({
    required this.message,
    required this.data,
  });

  factory NotificationScheduleResponseModel.fromJson(String str) =>
      NotificationScheduleResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory NotificationScheduleResponseModel.fromMap(
    Map<String, dynamic> json,
  ) => NotificationScheduleResponseModel(
    message: json["message"],
    data: List<NotificationScheduleData>.from(
      json["data"].map((x) => NotificationScheduleData.fromMap(x)),
    ),
  );

  Map<String, dynamic> toMap() => {
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toMap())),
  };
}

class NotificationScheduleData {
  final int id;
  final int medicationId;
  final int patientId;
  final int doctorId;
  final String scheduleTime;
  final DateTime startDate;
  final DateTime? endDate; // Nullable
  final bool isActive;
  final List<int> recipientFamilyIds; // Ini akan di-parse dari JSON string
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Additional fields joined from 'obat' and 'pasien' tables for convenience
  final String? medicationName;
  final String? medicationDosage;
  final String? medicationPhotoUrl;
  final String? patientName;
  final String? patientUniqueId;

  static const int defaultInt = 0;
  static const String defaultString = '';
  static const bool defaultBool = false;
  static DateTime get defaultDateTime => DateTime.now();

  NotificationScheduleData({
    required this.id,
    required this.medicationId,
    required this.patientId,
    required this.doctorId,
    required this.scheduleTime,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.recipientFamilyIds,
    required this.createdAt,
    this.updatedAt,
    this.medicationName,
    this.medicationDosage,
    this.medicationPhotoUrl,
    this.patientName,
    this.patientUniqueId,
  });

  factory NotificationScheduleData.fromJson(String str) =>
      NotificationScheduleData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory NotificationScheduleData.fromMap(Map<String, dynamic> json) {
    // Handling JSON parsing for recipient_family_ids
    List<int> parsedRecipientFamilyIds = [];
    if (json["recipientFamilyIds"] != null) {
      if (json["recipient_family_ids"] is String) {
        // Jika dari backend masih berupa string JSON
        try {
          final decoded = jsonDecode(json["recipientFamilyIds"]);
          if (decoded is List) {
            parsedRecipientFamilyIds = List<int>.from(decoded.map((x) => x));
          }
        } catch (e) {
          print("Error parsing recipientFamilyIds string: $e");
          // Fallback to empty list
        }
      } else if (json["recipient_family_ids"] is List) {
        // Jika dari backend sudah berupa List
        parsedRecipientFamilyIds = List<int>.from(
          json["recipient_family_ids"].map((x) => x),
        );
      }
    }

    return NotificationScheduleData(
      // PERBAIKAN: Gunakan static const variable yang sudah didefinisikan
      id:
          (json["id"] ??
                  json["notification_id"] ??
                  NotificationScheduleData.defaultInt)
              as int,
      medicationId:
          (json["medicationId"] ?? NotificationScheduleData.defaultInt) as int,
      patientId:
          (json["patientId"] ?? NotificationScheduleData.defaultInt) as int,
      doctorId:
          (json["doctorId"] ?? NotificationScheduleData.defaultInt) as int,
      scheduleTime:
          (json["scheduleTime"] ?? NotificationScheduleData.defaultString)
              as String,
      startDate:
          json["startDate"] != null
              ? DateTime.parse(json["startDate"])
              : NotificationScheduleData.defaultDateTime,
      endDate: json["endDate"] == null ? null : DateTime.parse(json["endDate"]),
      isActive:
          (json["isActive"] ?? NotificationScheduleData.defaultBool) as bool,
      recipientFamilyIds: parsedRecipientFamilyIds,
      createdAt:
          json["createdAt"] != null
              ? DateTime.parse(json["createdAt"])
              : NotificationScheduleData.defaultDateTime,
      updatedAt:
          json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),

      medicationName: json["medicationName"] as String?,
      medicationDosage: json["medicationDosage"] as String?,
      medicationPhotoUrl: json["medicationPhotoUrl"] as String?,
      patientName: json["patientName"] as String?,
      patientUniqueId: json["patientUniqueId"] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "medication_id": medicationId,
      "patient_id": patientId,
      "doctor_id": doctorId,
      "schedule_time": scheduleTime,
      "start_date":
          "${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}",
      "end_date":
          endDate == null
              ? null
              : "${endDate!.year.toString().padLeft(4, '0')}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}",
      "is_active": isActive ? 1 : 0,
      "recipient_family_ids":
          recipientFamilyIds, // Akan di-handle JSON.encode di repo/bloc
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
      "medication_name": medicationName,
      "medication_dosage": medicationDosage,
      "medication_photo_url": medicationPhotoUrl,
      "patient_name": patientName,
      "patient_unique_id": patientUniqueId,
    };
  }
}
