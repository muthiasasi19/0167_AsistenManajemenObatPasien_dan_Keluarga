import 'dart:convert';
import 'dart:developer' as developer;
import 'package:manajemen_obat/service/service_http_client.dart';

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

// Model untuk satu objek Obat
class Medication {
  final int id;
  final int patientId;
  final int? doctorId;
  final String medicationName;
  final String dosage;
  final MedicationSchedule schedule; // <--- Tetap MedicationSchedule
  final String? description;
  final String? photoUrl;
  final String? createdAt;
  final String? updatedAt;
  final String? status;
  final bool? isTaken;
  final String? consumptionTime;
  final String? consumptionNotes;
  final String? scheduledTime;

  Medication({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.medicationName,
    required this.dosage,
    required this.schedule,
    this.description,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.isTaken,
    this.consumptionTime,
    this.consumptionNotes,
    this.scheduledTime,
  });

  factory Medication.fromJson(String str) =>
      Medication.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Medication.fromMap(Map<String, dynamic> json) {
    developer.log('[Medication.fromMap] Raw JSON: $json');

    final int id = int.tryParse(json["id"]?.toString() ?? '0') ?? 0;
    final int patientId =
        int.tryParse(json["patientId"]?.toString() ?? '0') ?? 0;
    final int? doctorId = int.tryParse(json["doctorId"]?.toString() ?? '');

    final String medicationName = json["medicationName"] as String? ?? '';
    final String dosage = json["dosage"] as String? ?? '';

    MedicationSchedule parsedSchedule;
    final dynamic rawSchedule = json["schedule"];

    if (rawSchedule is Map<String, dynamic>) {
      parsedSchedule = MedicationSchedule.fromMap(rawSchedule);
    } else if (rawSchedule is String) {
      try {
        final decodedSchedule = jsonDecode(rawSchedule);
        if (decodedSchedule is Map<String, dynamic>) {
          parsedSchedule = MedicationSchedule.fromMap(decodedSchedule);
        } else {
          parsedSchedule = MedicationSchedule(
            type: 'unknown',
            notes: rawSchedule,
          );
        }
      } catch (e) {
        developer.log('Error decoding schedule string to JSON: $e');
        parsedSchedule = MedicationSchedule(
          type: 'unknown',
          notes: rawSchedule,
        );
      }
    } else {
      parsedSchedule = MedicationSchedule(
        type: 'unknown',
        notes: 'Invalid schedule format',
      );
    }

    final String? description = json["description"] as String?;
    final String? photoUrl = json["photoUrl"] as String?;
    final String? createdAt = json["createdAt"] as String?;
    final String? updatedAt = json["updatedAt"] as String?;
    final bool? isTaken = json["isTaken"] as bool?;
    final String? consumptionTime = json["consumptionTime"] as String?;
    final String? consumptionNotes = json["consumptionNotes"] as String?;
    final String? status = json["status"] as String?;
    final String? scheduledTime = json["scheduledTime"] as String?;

    final Medication medication = Medication(
      id: id,
      patientId: patientId,
      doctorId: doctorId,
      medicationName: medicationName,
      dosage: dosage,
      schedule: parsedSchedule,
      description: description,
      photoUrl: photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: status,
      isTaken: isTaken,
      consumptionTime: consumptionTime,
      consumptionNotes: consumptionNotes,
      scheduledTime: scheduledTime,
    );

    developer.log(
      '[Medication.fromMap] Parsed Medication: ${medication.medicationName}, ${medication.dosage}, ${medication.schedule.displayString}',
    );

    return medication;
  }

  Map<String, dynamic> toMap() => {
    "id": id,
    "patientId": patientId,
    "doctorId": doctorId,
    "medicationName": medicationName,
    "dosage": dosage,
    "schedule": schedule.toMap(),
    "description": description,
    "photoUrl": photoUrl,
    "createdAt": createdAt,
    "updatedAt": updatedAt,
    "status": status,
    "isTaken": isTaken,
    "consumptionTime": consumptionTime,
    "consumptionNotes": consumptionNotes,
    "scheduledTime": scheduledTime,
  };

  String? get fullPhotoUrl {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return null;
    }
    // baseUrl dari ServiceHttpClient adalah 'http://IP:PORT/api/'
    // photoUrl dari backend adalah '/api/uploads/filename.jpg'
    // Cukup gabungkan baseUrl dengan photoUrl, TETAPI hapus '/api/' dari awal photoUrl
    // agar tidak ada '/api/api/' ganda.
    return '${ServiceHttpClient().baseUrl}${photoUrl!.replaceFirst('/api/', '')}';
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

  String? get fullPhotoUrl {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return null;
    }
    return '${ServiceHttpClient().baseUrl}${photoUrl!.replaceFirst('/api/', '')}';
    // Atau yang lebih aman (seperti yang sebelumnya saya berikan):
    // return '${ServiceHttpClient().baseUrl}${photoUrl!.replaceFirst('/api/', '')}';
  }

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
