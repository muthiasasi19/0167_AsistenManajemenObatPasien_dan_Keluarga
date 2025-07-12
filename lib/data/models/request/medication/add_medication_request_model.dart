import 'dart:convert';
import 'dart:io';

import 'package:manajemen_obat/data/models/response/medication_response_model.dart';

class AddMedicationRequestModel {
  final String medicationName;
  final String dosage;
  final MedicationSchedule schedule;
  final String? description;
  final String? photoUrl;
  final File? photoFile;

  AddMedicationRequestModel({
    required this.medicationName,
    required this.dosage,
    required this.schedule,
    this.description,
    this.photoUrl,
    this.photoFile,
  });

  AddMedicationRequestModel copyWith({
    String? medicationName,
    String? dosage,
    MedicationSchedule? schedule,
    String? description,
    String? photoUrl,
    File? photoFile,
  }) {
    return AddMedicationRequestModel(
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      schedule: schedule ?? this.schedule,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      photoFile: photoFile ?? this.photoFile,
    );
  }

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
    "medicationName": medicationName,
    "dosage": dosage,
    "schedule": schedule.toMap(),
    "description": description,
    "photoUrl": photoUrl,
  };
}
