import 'dart:convert';

class PatientLocationResponseModel {
  final String? message;
  final PatientLocationData? data; // Bisa null jika lokasi tidak tersedia

  PatientLocationResponseModel({this.message, this.data});

  factory PatientLocationResponseModel.fromJson(String str) =>
      PatientLocationResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PatientLocationResponseModel.fromMap(Map<String, dynamic> json) =>
      PatientLocationResponseModel(
        message: json["message"],
        data:
            json["data"] == null
                ? null
                : PatientLocationData.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {"message": message, "data": data?.toMap()};
}

class PatientLocationData {
  final double? latitude;
  final double? longitude;
  final String? timestamp;

  PatientLocationData({this.latitude, this.longitude, this.timestamp});

  factory PatientLocationData.fromJson(String str) =>
      PatientLocationData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PatientLocationData.fromMap(Map<String, dynamic> json) =>
      PatientLocationData(
        latitude:
            json["latitude"] != null
                ? double.tryParse(json["latitude"].toString())
                : null,
        longitude:
            json["longitude"] != null
                ? double.tryParse(json["longitude"].toString())
                : null,
        timestamp: json["timestamp"] as String?,
      );

  Map<String, dynamic> toMap() => {
    "latitude": latitude,
    "longitude": longitude,
    "timestamp": timestamp,
  };
}
