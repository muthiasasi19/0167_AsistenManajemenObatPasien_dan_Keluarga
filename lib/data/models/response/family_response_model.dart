// lib/data/models/response/family_response_model.dart

import 'dart:convert'; // Diperlukan untuk json.decode dan json.encode

class FamilyResponseModel {
  final String? status;
  final String? message;
  final FamilyData? data;

  FamilyResponseModel({this.status, this.message, this.data});

  // Factory constructor untuk membuat instance FamilyResponseModel dari string JSON
  factory FamilyResponseModel.fromJson(String str) =>
      FamilyResponseModel.fromMap(json.decode(str));

  // Factory constructor untuk membuat instance FamilyResponseModel dari Map (hasil decode JSON)
  factory FamilyResponseModel.fromMap(Map<String, dynamic> json) {
    return FamilyResponseModel(
      status: json['status'] as String?,
      message: json['message'] as String?,
      data:
          json['data'] == null
              ? null
              : FamilyData.fromMap(json['data'] as Map<String, dynamic>),
    );
  }

  // Metode untuk mengonversi instance FamilyResponseModel ke Map
  Map<String, dynamic> toMap() {
    return {'status': status, 'message': message, 'data': data?.toMap()};
  }

  // Metode untuk mengonversi instance FamilyResponseModel ke string JSON
  String toJson() => json.encode(toMap());
}

class FamilyData {
  final String
  id; // Global ID dari tabel 'keluarga' (misal: integer, tapi di Dart sering dihandle sebagai String)
  final String
  idKeluargaUnik; // ID unik keluarga dari tabel 'keluarga.id_keluarga'
  final String username; // Dari tabel 'users'
  final String role; // Dari tabel 'users'
  final String nama; // Dari tabel 'keluarga.nama'
  final String? nomorTelepon; // Dari tabel 'keluarga.nomor_telepon'
  final String? alamat; // Dari tabel 'keluarga.alamat'

  FamilyData({
    required this.id,
    required this.idKeluargaUnik,
    required this.username,
    required this.role,
    required this.nama,
    this.nomorTelepon,
    this.alamat,
  });

  // Factory constructor untuk membuat instance FamilyData dari Map
  factory FamilyData.fromMap(Map<String, dynamic> json) {
    return FamilyData(
      id:
          json['id']?.toString() ??
          '', // Pastikan ini 'id' dari tabel keluarga (global ID)
      idKeluargaUnik:
          json['id_keluarga'] as String? ?? '', // ID unik keluarga dari backend
      username: json['username'] as String? ?? 'N/A',
      role: json['role'] as String? ?? 'N/A',
      nama: json['nama'] as String? ?? 'Nama Tidak Diketahui',
      nomorTelepon: json['nomor_telepon'] as String?,
      alamat: json['alamat'] as String?,
    );
  }

  // Metode untuk mengonversi instance FamilyData ke Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_keluarga': idKeluargaUnik,
      'username': username,
      'role': role,
      'nama': nama,
      'nomor_telepon': nomorTelepon,
      'alamat': alamat,
    };
  }

  // Factory constructor untuk membuat instance FamilyData dari string JSON
  factory FamilyData.fromJson(String str) =>
      FamilyData.fromMap(json.decode(str));

  // Metode untuk mengonversi instance FamilyData ke string JSON
  String toJson() => json.encode(toMap());
}
