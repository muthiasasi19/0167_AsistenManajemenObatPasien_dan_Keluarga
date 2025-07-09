import 'dart:convert';
import 'dart:developer' as developer;

class MedicationSchedule {
  final String type;
  final List<String>? times;
  final List<String>? daysOfWeek;
  final String? notes;

  MedicationSchedule({
    required this.type,
    this.times,
    this.daysOfWeek,
    this.notes,
  });

  factory MedicationSchedule.fromMap(Map<String, dynamic> map) {
    return MedicationSchedule(
      type: map['type'] as String? ?? 'unknown',
      times: (map['times'] as List<dynamic>?)?.map((e) => e as String).toList(),
      daysOfWeek:
          (map['daysOfWeek'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'times': times,
      'daysOfWeek': daysOfWeek,
      'notes': notes,
    };
  }

  // Helper untuk menampilkan jadwal dengan format yang mudah dibaca di UI
  String get displayString {
    String result = '';
    switch (type) {
      case 'daily_fixed_times':
        if (times != null && times!.isNotEmpty) {
          result = '${times!.length}x sehari (${times!.join(', ')})';
        } else {
          result = 'Harian';
        }
        break;
      case 'specific_days_of_week':
        if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          result = 'Setiap ${daysOfWeek!.join(', ')}';
          if (times != null && times!.isNotEmpty) {
            result += ' (${times!.join(', ')})';
          }
        } else {
          result = 'Hari tertentu';
        }
        break;
      case 'as_needed':
        result = 'Sesuai Kebutuhan (PRN)';
        break;
      case 'unknown':
        result = notes ?? 'Jadwal Tidak Diketahui';
        break;
      default:
        result = 'Jadwal Tidak Diketahui';
        break;
    }
    if (type != 'unknown' && notes != null && notes!.isNotEmpty) {
      result += ' - $notes';
    }
    return result;
  }
}

class MedicationsListResponseModel {
  final String? message;
  final List<Medication> data;

  MedicationsListResponseModel({this.message, required this.data});

  factory MedicationsListResponseModel.fromJson(String str) =>
      MedicationsListResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory MedicationsListResponseModel.fromMap(Map<String, dynamic> json) =>
      MedicationsListResponseModel(
        message: json["message"],
        data:
            (json["data"] as List<dynamic>?)
                ?.map((x) => Medication.fromMap(x as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toMap() => {
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toMap())),
  };
}

class SingleMedicationResponseModel {
  final String? message;
  final Medication? data;

  SingleMedicationResponseModel({this.message, this.data});

  factory SingleMedicationResponseModel.fromJson(String str) =>
      SingleMedicationResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory SingleMedicationResponseModel.fromMap(Map<String, dynamic> json) =>
      SingleMedicationResponseModel(
        message: json["message"],
        data: json["data"] == null ? null : Medication.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {"message": message, "data": data?.toMap()};
}

class TodaysMedicationSession {
  final int? id;
  final int medicationId;
  final String medicationName;
  final String dosage;
  final String? description;
  final String? photoUrl;
  final String? scheduledTime;
  final String status; // 'Diminum', 'Terlewat', 'Menunggu'
  final bool isTaken; // Untuk UI checkbox
  final String? scheduleType;
  final String? consumptionTime;
  final String? consumptionNotes;

  TodaysMedicationSession({
    required this.medicationId,
    this.id,
    required this.medicationName,
    required this.dosage,
    this.description,
    this.photoUrl,
    this.scheduledTime,
    required this.status,
    required this.isTaken,
    this.scheduleType,
    this.consumptionTime,
    this.consumptionNotes,
  });

  factory TodaysMedicationSession.fromMap(Map<String, dynamic> map) {
    return TodaysMedicationSession(
      id:
          map['consumptionRecordId'] != null
              ? (map['consumptionRecordId'] is int
                  ? map['consumptionRecordId'] as int
                  : int.tryParse(map['consumptionRecordId'].toString()))
              : null,
      medicationId:
          map['medicationId'] is int
              ? map['medicationId'] as int
              : int.tryParse(map['medicationId']?.toString() ?? '0') ?? 0,
      medicationName: map['medicationName'] as String,
      dosage: map['dosage'] as String,
      description: map['description'] as String?,
      photoUrl: map['photoUrl'] as String?,
      scheduledTime: map['scheduledTime'] as String?,
      status: map['status'] as String,
      isTaken: map['isTaken'] as bool? ?? false,
      scheduleType: map['scheduleType'] as String?,
      consumptionTime: map['consumptionTime'] as String?,
      consumptionNotes: map['consumptionNotes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'dosage': dosage,
      'description': description,
      'photoUrl': photoUrl,
      'scheduledTime': scheduledTime,
      'status': status,
      'isTaken': isTaken,
      'scheduleType': scheduleType,
      'consumptionTime': consumptionTime,
      'consumptionNotes': consumptionNotes,
    };
  }
}

// Model untuk respons daftar TodaysMedicationSession
class TodaysMedicationSessionListResponseModel {
  final String? message;
  final List<TodaysMedicationSession> data;

  TodaysMedicationSessionListResponseModel({this.message, required this.data});

  factory TodaysMedicationSessionListResponseModel.fromJson(String str) =>
      TodaysMedicationSessionListResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory TodaysMedicationSessionListResponseModel.fromMap(
    Map<String, dynamic> json,
  ) {
    return TodaysMedicationSessionListResponseModel(
      message: json["message"] as String?,
      data:
          (json["data"] as List<dynamic>?)
              ?.map(
                (x) =>
                    TodaysMedicationSession.fromMap(x as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() => {
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toMap())),
  };
}
