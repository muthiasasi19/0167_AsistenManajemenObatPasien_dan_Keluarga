import 'dart:convert';
import 'dart:developer' as developer; // DARI SINI YAH: Import developer
import 'package:manajemen_obat/data/models/response/medication_response_model.dart'; // DARI SINI YAH: Import MedicationSchedule

class MedicationHistoryResponseModel {
  final String? message;
  final List<MedicationHistoryData> data;

  MedicationHistoryResponseModel({this.message, required this.data});

  factory MedicationHistoryResponseModel.fromJson(String str) =>
      MedicationHistoryResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory MedicationHistoryResponseModel.fromMap(Map<String, dynamic> json) =>
      MedicationHistoryResponseModel(
        message: json["message"],
        data: List<MedicationHistoryData>.from(
          (json["data"] as List<dynamic>?)?.map(
                (x) => MedicationHistoryData.fromMap(x as Map<String, dynamic>),
              ) ??
              [],
        ),
      );

  Map<String, dynamic> toMap() => {
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toMap())),
  };
}

class MedicationHistoryData {
  final int? id;
  final int? medicationId; // id_obat
  final int? patientId; // id_pasien
  final String? status; // 'taken' atau 'missed'
  final String? notes; // catatan
  final String? consumptionTime; // waktu_konsumsi (DATETIME string)
  final String? medicationName; // dari JOIN obat
  final String? dosage; // dari JOIN obat
  final MedicationSchedule?
  schedule; // DARI SINI YAH: Ubah tipe data schedule menjadi objek MedicationSchedule
  final String?
  scheduledTime; // DARI SINI YAH: Tambahkan scheduledTime yang baru dari DB

  MedicationHistoryData({
    this.id,
    this.medicationId,
    this.patientId,
    this.status,
    this.notes,
    this.consumptionTime,
    this.medicationName,
    this.dosage,
    this.schedule,
    this.scheduledTime, // SAMPAI SINI, OKE
  });

  factory MedicationHistoryData.fromJson(String str) =>
      MedicationHistoryData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory MedicationHistoryData.fromMap(Map<String, dynamic> json) {
    // DARI SINI YAH
    MedicationSchedule? parsedSchedule;
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
        developer.log('Error decoding schedule string in history model: $e');
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

    return MedicationHistoryData(
      id: json["id"] as int?,
      medicationId:
          json["medicationId"] as int? ??
          json["id_obat"] as int?, // Sesuaikan dengan kunci backend `id_obat`
      patientId:
          json["patientId"] as int? ??
          json["id_pasien"]
              as int?, // Sesuaikan dengan kunci backend `id_pasien`
      status: json["status"] as String?,
      notes:
          json["notes"] as String? ??
          json["catatan"]
              as String?, // Sesuaikan dengan kunci backend `catatan`
      consumptionTime:
          json["consumptionTime"] as String? ??
          json["waktu_konsumsi"]
              as String?, // Sesuaikan dengan kunci backend `waktu_konsumsi`
      medicationName:
          json["medicationName"] as String? ?? json["nama_obat"] as String?,
      dosage: json["dosage"] as String? ?? json["dosis"] as String?,
      schedule: parsedSchedule,
      scheduledTime: json["scheduled_time"] as String?, // SAMPAI SINI, OKE
    );
  }

  get fullPhotoUrl => null;

  Map<String, dynamic> toMap() => {
    "id": id,
    "id_obat": medicationId,
    "id_pasien": patientId,
    "status": status,
    "catatan": notes,
    "waktu_konsumsi": consumptionTime,
    "nama_obat": medicationName,
    "dosis": dosage,
    "jadwal": schedule?.toMap(),
  };
}
