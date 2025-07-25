import 'dart:convert';

class RegisterRequestModel {
  final String username;
  final String password;
  final String role;
  // Data Pasien (nama properti disesuaikan dengan yang diharapkan backend authController.js)
  final String? patientName;
  final String? patientDob; // Tanggal lahir (String, misal 'YYYY-MM-DD')
  final String? patientGender;
  final String? patientPhone;
  final String? patientAddress;
  // Data Dokter (nama properti disesuaikan dengan yang diharapkan backend authController.js)
  final String? doctorName;
  final String? doctorSpecialization;
  final String? doctorPhone;
  final String? doctorAddress;
  // Data Keluarga (nama properti disesuaikan dengan yang diharapkan backend authController.js)
  final String? familyName;
  final String? familyPhone;
  final String? familyAddress;
  // Jika ada ID pasien yang diikuti oleh keluarga, tambahkan di sini
  // final String? familyFollowedPatientId;

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
    // this.familyFollowedPatientId,
  });

  /// Convert JSON string to object (tidak selalu digunakan untuk request model)
  factory RegisterRequestModel.fromJson(String str) =>
      RegisterRequestModel.fromMap(json.decode(str));

  /// Convert object to JSON string
  String toJson() => json.encode(toMap());

  /// Convert Map to object (tidak selalu digunakan untuk request model)
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
        // familyFollowedPatientId: json['familyFollowedPatientId'],
      );

  /// Convert object to Map (INI PENTING: sesuaikan kunci dengan yang diharapkan backend)
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
        // if (familyFollowedPatientId != null) {
        //   data['id_pasien_yang_diikuti'] = familyFollowedPatientId; // Contoh nama kunci di backend
        // }
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
