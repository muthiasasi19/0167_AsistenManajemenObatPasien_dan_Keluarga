// lib/data/models/response/patient_search_result_model.dart
import 'dart:convert';

class PatientSearchResult {
  final int idGlobal;
  final String idUnik;
  final String nama;

  PatientSearchResult({
    required this.idGlobal,
    required this.idUnik,
    required this.nama,
  });

  factory PatientSearchResult.fromJson(String str) =>
      PatientSearchResult.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PatientSearchResult.fromMap(Map<String, dynamic> json) =>
      PatientSearchResult(
        idGlobal: json["idGlobal"],
        idUnik: json["idUnik"],
        nama: json["nama"],
      );

  Map<String, dynamic> toMap() => {
    "idGlobal": idGlobal,
    "idUnik": idUnik,
    "nama": nama,
  };

  @override
  String toString() {
    return 'PatientSearchResult(idGlobal: $idGlobal, idUnik: $idUnik, nama: $nama)';
  }
}

// Model untuk respons daftar hasil pencarian pasien
class PatientSearchListResponseModel {
  final String? message;
  final List<PatientSearchResult> data;

  PatientSearchListResponseModel({this.message, required this.data});

  factory PatientSearchListResponseModel.fromJson(String str) =>
      PatientSearchListResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PatientSearchListResponseModel.fromMap(Map<String, dynamic> json) =>
      PatientSearchListResponseModel(
        message: json["message"],
        data:
            (json["data"] as List<dynamic>?)
                ?.map(
                  (x) => PatientSearchResult.fromMap(x as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );

  Map<String, dynamic> toMap() => {
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toMap())),
  };
}
