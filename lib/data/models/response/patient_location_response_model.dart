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
  final String? timestamp; // DATETIME string dari backend

  PatientLocationData({this.latitude, this.longitude, this.timestamp});

  factory PatientLocationData.fromJson(String str) =>
      PatientLocationData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PatientLocationData.fromMap(Map<String, dynamic> json) =>
      PatientLocationData(
        latitude: (json["latitude"] as num?)?.toDouble(), // Pastikan double
        longitude: (json["longitude"] as num?)?.toDouble(), // Pastikan double
        timestamp: json["timestamp"] as String?,
      );

  Map<String, dynamic> toMap() => {
    "latitude": latitude,
    "longitude": longitude,
    "timestamp": timestamp,
  };
}
