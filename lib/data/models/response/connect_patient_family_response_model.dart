import 'dart:convert';

class FamilyConnectedPatientResponseModel {
  final String? message;
  final List<FamilyConnectedPatientData> data;

  FamilyConnectedPatientResponseModel({this.message, required this.data});

  factory FamilyConnectedPatientResponseModel.fromJson(String str) =>
      FamilyConnectedPatientResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory FamilyConnectedPatientResponseModel.fromMap(
    Map<String, dynamic> json,
  ) => FamilyConnectedPatientResponseModel(
    message: json["message"],
    data: List<FamilyConnectedPatientData>.from(
      (json["data"] as List<dynamic>?)?.map(
            (x) =>
                FamilyConnectedPatientData.fromMap(x as Map<String, dynamic>),
          ) ??
          [],
    ),
  );

  Map<String, dynamic> toMap() => {
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toMap())),
  };
}
