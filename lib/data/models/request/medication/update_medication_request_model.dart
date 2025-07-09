import 'dart:convert';

import 'package:manajemen_obat/data/models/response/medication_response_model.dart';

class UpdateMedicationRequestModel {
  final String medicationName;
  final String dosage;
  final MedicationSchedule schedule;
  final String? description;
  final String? photoUrl;

  UpdateMedicationRequestModel({
    required this.medicationName,
    required this.dosage,
    required this.schedule,
    this.description,
    this.photoUrl,
  });

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
    "medicationName": medicationName,
    "dosage": dosage,
    "schedule": schedule.toMap(),
    "description": description,
    "photoUrl": photoUrl,
  };
}
