import 'dart:convert';

class AuthResponseModel {
  final String? message;
  final int? statusCode;
  final User? user;

  AuthResponseModel({this.message, this.statusCode, this.user});

  factory AuthResponseModel.fromJson(String str) =>
      AuthResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory AuthResponseModel.fromMap(Map<String, dynamic> json) =>
      AuthResponseModel(
        message: json["message"],
        statusCode: json["status_code"],
        user: json["data"] == null ? null : User.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
    "message": message,
    "status_code": statusCode,
    "data": user?.toMap(),
  };
}

class User {
  final String? username;
  final String? role;
  final String? token;
  final String? idPasien;
  final String? jenisKelamin;
  final String? idDokter;
  final String? spesialis;

  User({
    this.username,
    this.role,
    this.token,
    this.idPasien,
    this.jenisKelamin,
    this.idDokter,
    this.spesialis,
  });

  factory User.fromJson(String str) => User.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory User.fromMap(Map<String, dynamic> json) => User(
    username: json["username"],
    role: json["role"],
    token: json["token"],
    idPasien: json["id_pasien"],
    jenisKelamin: json["jenis_kelamin"],
    idDokter: json["id_dokter"],
    spesialis: json["spesialis"],
  );

  Map<String, dynamic> toMap() => {
    "username": username,
    "role": role,
    "token": token,
    "id_pasien": idPasien,
    "jenis_kelamin": jenisKelamin,
    "id_dokter": idDokter,
    "spesialis": spesialis,
  };
}
