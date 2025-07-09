import 'dart:convert';
import 'dart:developer' as developer;
import 'package:manajemen_obat/data/models/response/medication_response_model.dart';

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
