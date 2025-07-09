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

class FamilyConnectedPatientData {
  final int? idGlobal;
  final String? idUnik;
  final String? nama;
  final String? tanggalLahir;
  final String? jenisKelamin;
  final String? nomorTelepon;
  final String? alamat;

  FamilyConnectedPatientData({
    this.idGlobal,
    this.idUnik,
    this.nama,
    this.tanggalLahir,
    this.jenisKelamin,
    this.nomorTelepon,
    this.alamat,
  });

  factory FamilyConnectedPatientData.fromJson(String str) =>
      FamilyConnectedPatientData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory FamilyConnectedPatientData.fromMap(Map<String, dynamic> json) =>
      FamilyConnectedPatientData(
        idGlobal: json["idGlobal"] as int?,
        idUnik: json["idUnik"] as String?,
        nama: json["nama"] as String?,
        tanggalLahir: json["tanggalLahir"] as String?,
        jenisKelamin: json["jenisKelamin"] as String?,
        nomorTelepon: json["nomorTelepon"] as String?,
        alamat: json["alamat"] as String?,
      );

  Map<String, dynamic> toMap() => {
    "idGlobal": idGlobal,
    "idUnik": idUnik,
    "nama": nama,
    "tanggalLahir": tanggalLahir,
    "jenisKelamin": jenisKelamin,
    "nomorTelepon": nomorTelepon,
    "alamat": alamat,
  };
}
