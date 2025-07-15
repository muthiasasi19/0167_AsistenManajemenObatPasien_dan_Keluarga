import 'dart:convert';

class LoginResponseModel {
  final String? message;
  final String? token;
  final User? user;

  LoginResponseModel({this.message, this.token, this.user});

  factory LoginResponseModel.fromJson(String str) =>
      LoginResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory LoginResponseModel.fromMap(Map<String, dynamic> json) =>
      LoginResponseModel(
        message: json["message"],
        token: json["token"],
        user: json["user"] == null ? null : User.fromMap(json["user"]),
      );

  Map<String, dynamic> toMap() => {
    "message": message,
    "token": token,
    "user": user?.toMap(),
  };
}

class User {
  final int? id;
  final String? username;
  final String? role;

  final int? patientGlobalId; // Backend JWT payload: patientGlobalId (INT)
  final int? doctorGlobalId; // Backend JWT payload: doctorGlobalId (INT)
  final int? familyGlobalId; // Backend JWT payload: familyGlobalId (INT)

  // Pasien-specific fields (yang sudah ada, biarkan tetap)
  final String? idPasien; // Backend: id_pasien (VARCHAR unik, misal PSN...)
  final String? namaPasien;
  final String? tanggalLahirPasien;
  final String? jenisKelaminPasien;
  final String? nomorTeleponPasien;
  final String? alamatPasien;

  // Dokter-specific fields (yang sudah ada, biarkan tetap)
  final String? idDokter; // Backend: id_dokter (VARCHAR unik, misal DKTR...)
  final String? namaDokter; // Backend: name
  final String? spesialisasiDokter; // Backend: specialization
  final String? nomorTeleponDokter; // Backend: phoneNumber
  final String? alamatDokter; // Backend: address

  // Keluarga-specific fields (yang sudah ada, biarkan tetap)
  final String? idKeluarga; // Backend: id_keluarga (VARCHAR unik, misal KLG...)
  final String? namaKeluarga; // Backend: name
  final String? nomorTeleponKeluarga; // Backend: phoneNumber
  final String? alamatKeluarga; // Backend: address

  User({
    this.id,
    this.username,
    this.role,
    this.patientGlobalId,
    this.doctorGlobalId,
    this.familyGlobalId,
    // Pasien
    this.idPasien,
    this.namaPasien,
    this.tanggalLahirPasien,
    this.jenisKelaminPasien,
    this.nomorTeleponPasien,
    this.alamatPasien,
    // Dokter
    this.idDokter,
    this.namaDokter,
    this.spesialisasiDokter,
    this.nomorTeleponDokter,
    this.alamatDokter,
    // Keluarga
    this.idKeluarga,
    this.namaKeluarga,
    this.nomorTeleponKeluarga,
    this.alamatKeluarga,
  });

  factory User.fromJson(String str) => User.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  // Memetakan  JSON dari backend ke properti Dart
  factory User.fromMap(Map<String, dynamic> json) {
    final String? role = json["role"]?.toLowerCase();

    // Inisialisasi variabel lokal untuk setiap properti
    String? parsedIdPasien;
    String? parsedNamaPasien;
    String? parsedTanggalLahirPasien;
    String? parsedJenisKelaminPasien;
    String? parsedNomorTeleponPasien;
    String? parsedAlamatPasien;
    int? parsedPatientGlobalId;

    String? parsedIdDokter;
    String? parsedNamaDokter;
    String? parsedSpesialisasiDokter;
    String? parsedNomorTeleponDokter;
    String? parsedAlamatDokter;
    int? parsedDoctorGlobalId;

    String? parsedIdKeluarga;
    String? parsedNamaKeluarga;
    String? parsedNomorTeleponKeluarga;
    String? parsedAlamatKeluarga;
    int? parsedFamilyGlobalId;

    // Parsing data berdasarkan peran (role)
    if (role == 'pasien') {
      parsedIdPasien =
          json["id_pasien"] as String?; // Ini adalah ID unik PSN...
      parsedNamaPasien = json["name"] as String?; // Backend mengirim 'name'
      parsedTanggalLahirPasien = json["dateOfBirth"] as String?;
      parsedJenisKelaminPasien = json["gender"] as String?;
      parsedNomorTeleponPasien = json["phoneNumber"] as String?;
      parsedAlamatPasien = json["address"] as String?;
      parsedPatientGlobalId =
          json["patientGlobalId"] is int
              ? json["patientGlobalId"] as int
              : (json["patientGlobalId"] is String
                  ? int.tryParse(json["patientGlobalId"])
                  : null);
    } else if (role == 'dokter') {
      parsedIdDokter =
          json["id_dokter"] as String?; // Ini adalah ID unik DKTR...
      parsedNamaDokter = json["name"] as String?;
      parsedSpesialisasiDokter = json["specialization"] as String?;
      parsedNomorTeleponDokter = json["phoneNumber"] as String?;
      parsedAlamatDokter = json["address"] as String?;
      parsedDoctorGlobalId = json["doctorGlobalId"] as int?;
    } else if (role == 'keluarga') {
      parsedIdKeluarga =
          json["id_keluarga"] as String?; // Ini adalah ID unik KLG...
      parsedNamaKeluarga = json["name"] as String?;
      parsedNomorTeleponKeluarga = json["phoneNumber"] as String?;
      parsedAlamatKeluarga = json["address"] as String?;
      parsedFamilyGlobalId =
          json["familyGlobalId"] is int
              ? json["familyGlobalId"] as int
              : (json["familyGlobalId"] is String
                  ? int.tryParse(json["familyGlobalId"])
                  : null);
    }

    return User(
      id: json["id"] as int?,
      username: json["username"] as String?,
      role: json["role"] as String?,
      // Masukkan properti baru ke konstruktor User
      patientGlobalId: parsedPatientGlobalId,
      doctorGlobalId: parsedDoctorGlobalId,
      familyGlobalId: parsedFamilyGlobalId,
      // Pasien
      idPasien: parsedIdPasien,
      namaPasien: parsedNamaPasien,
      tanggalLahirPasien: parsedTanggalLahirPasien,
      jenisKelaminPasien: parsedJenisKelaminPasien,
      nomorTeleponPasien: parsedNomorTeleponPasien,
      alamatPasien: parsedAlamatPasien,
      // Dokter
      idDokter: parsedIdDokter,
      namaDokter: parsedNamaDokter,
      spesialisasiDokter: parsedSpesialisasiDokter,
      nomorTeleponDokter: parsedNomorTeleponDokter,
      alamatDokter: parsedAlamatDokter,
      // Keluarga
      idKeluarga: parsedIdKeluarga,
      namaKeluarga: parsedNamaKeluarga,
      nomorTeleponKeluarga: parsedNomorTeleponKeluarga,
      alamatKeluarga: parsedAlamatKeluarga,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      "id": id,
      "username": username,
      "role": role,
      "patientGlobalId": patientGlobalId,
      "doctorGlobalId": doctorGlobalId,
      "familyGlobalId": familyGlobalId,
    };

    // Tambahkan data spesifik peran
    if (role?.toLowerCase() == 'pasien') {
      data["id_pasien"] = idPasien;
      data["name"] = namaPasien;
      data["dateOfBirth"] = tanggalLahirPasien;
      data["gender"] = jenisKelaminPasien;
      data["phoneNumber"] = nomorTeleponPasien;
      data["address"] = alamatPasien;
    } else if (role?.toLowerCase() == 'dokter') {
      data["id_dokter"] = idDokter;
      data["name"] = namaDokter;
      data["specialization"] = spesialisasiDokter;
      data["phoneNumber"] = nomorTeleponDokter;
      data["address"] = alamatDokter;
    } else if (role?.toLowerCase() == 'keluarga') {
      data["id_keluarga"] = idKeluarga;
      data["name"] = namaKeluarga;
      data["phoneNumber"] = nomorTeleponKeluarga;
      data["address"] = alamatKeluarga;
    }
    return data;
  }
}
