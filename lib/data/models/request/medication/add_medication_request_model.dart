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

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
    "medicationName": medicationName,
    "dosage": dosage,
    "schedule": schedule.toMap(),
    "description": description,
    "photoUrl": photoUrl,
  };

  @override
  List<Object?> get props => [
    medicationName,
    dosage,
    schedule,
    description,
    photoUrl,
    photoFile,
  ];
}
