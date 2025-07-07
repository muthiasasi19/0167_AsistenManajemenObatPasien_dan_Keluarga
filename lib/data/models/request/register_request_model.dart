import 'dart:convert';

class RegisterRequestModel {
  final String username;
  final String password;
  final String role;
  // Data Pasien
  final String? patientName;
  final String? patientDob;
  final String? patientGender;
  final String? patientPhone;
  final String? patientAddress;
  // Data Dokter
  final String? doctorName;
  final String? doctorSpecialization;
  final String? doctorPhone;
  final String? doctorAddress;
  // Data Keluarga
  final String? familyName;
  final String? familyPhone;
  final String? familyAddress;

  RegisterRequestModel({
    required this.username,
    required this.password,
    required this.role,
    this.patientName,
    this.patientDob,
    this.patientGender,
    this.patientPhone,
    this.patientAddress,
    this.doctorName,
    this.doctorSpecialization,
    this.doctorPhone,
    this.doctorAddress,
    this.familyName,
    this.familyPhone,
    this.familyAddress,
  });

  /// Convert JSON string to object
  factory RegisterRequestModel.fromJson(String str) =>
      RegisterRequestModel.fromMap(json.decode(str));

  /// Convert object to JSON string
  String toJson() => json.encode(toMap());

  /// Convert Map to object
  factory RegisterRequestModel.fromMap(Map<String, dynamic> json) =>
      RegisterRequestModel(
        username: json['username'],
        password: json['password'],
        role: json['role'],
        patientName: json['patientName'],
        patientDob: json['patientDob'],
        patientGender: json['patientGender'],
        patientPhone: json['patientPhone'],
        patientAddress: json['patientAddress'],
        doctorName: json['doctorName'],
        doctorSpecialization: json['doctorSpecialization'],
        doctorPhone: json['doctorPhone'],
        doctorAddress: json['doctorAddress'],
        familyName: json['familyName'],
        familyPhone: json['familyPhone'],
        familyAddress: json['familyAddress'],
      );

  /// Convert object to Map
  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'username': username,
      'password': password,
      'role': role,
    };

    switch (role.toLowerCase()) {
      case 'pasien':
        data['patientName'] = patientName;
        data['patientDob'] = patientDob;
        data['patientGender'] = patientGender;
        data['patientPhone'] = patientPhone;
        data['patientAddress'] = patientAddress;
        break;
      case 'keluarga':
        data['familyName'] = familyName;
        data['familyPhone'] = familyPhone;
        data['familyAddress'] = familyAddress;
        break;
      case 'dokter':
        data['doctorName'] = doctorName;
        data['doctorSpecialization'] = doctorSpecialization;
        data['doctorPhone'] = doctorPhone;
        data['doctorAddress'] = doctorAddress;
        break;
    }
    return data;
  }
}
