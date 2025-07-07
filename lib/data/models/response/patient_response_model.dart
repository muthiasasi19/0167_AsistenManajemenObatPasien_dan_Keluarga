import 'dart:convert';
import 'dart:developer' as developer;

class Patient {
  final String id;
  final String name;
  final String patientId;
  final String? dateOfBirth;
  final String? gender;
  final String? phoneNumber;
  final String? address;
  final String? connectedDoctorId;

  Patient({
    required this.id,
    required this.name,
    required this.patientId,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.address,
    this.connectedDoctorId,
  });

  factory Patient.fromJson(String str) => Patient.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Patient.fromMap(Map<String, dynamic> json) {
    developer.log('[Patient.fromMap] Raw JSON: $json');

    final String id =
        json["patientGlobalId"]?.toString() ??
        ''; // Mengambil dari "patientGlobalId"
    final String patientId =
        json["patientUniqueId"] as String? ??
        ''; // Mengambil dari "patientUniqueId"
    final String name = json["patientName"] as String? ?? '';

    final String? dateOfBirth = json["dateOfBirth"] as String?;
    final String? gender = json["gender"] as String?;
    final String? phoneNumber = json["phoneNumber"] as String?;
    final String? address = json["address"] as String?;
    final String? connectedDoctorId =
        json["doctorId"]?.toString(); // Mengambil dari "doctorId"

    developer.log(
      '[Patient.fromMap] Parsed Patient: Name="$name", PatientID="$patientId", GlobalID="$id"',
    );

    return Patient(
      id: id,
      patientId: patientId,
      name: name,
      dateOfBirth: dateOfBirth,
      gender: gender,
      phoneNumber: phoneNumber,
      address: address,
      connectedDoctorId: connectedDoctorId,
    );
  }

  Map<String, dynamic> toMap() => {
    // Ini adalah kunci yang akan digunakan saat Patient objek diubah menjadi Map/JSON.
    "patientGlobalId": id,
    "patientUniqueId": patientId,
    "patientName": name,
    "dateOfBirth": dateOfBirth,
    "gender": gender,
    "phoneNumber": phoneNumber,
    "address": address,
    "doctorId": connectedDoctorId,
  };
}

// Model untuk respons yang berisi daftar pasien
class PatientsListResponseModel {
  final String? message;
  final List<Patient> data; // List pasien

  PatientsListResponseModel({this.message, required this.data});

  factory PatientsListResponseModel.fromJson(String str) =>
      PatientsListResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PatientsListResponseModel.fromMap(Map<String, dynamic> json) =>
      PatientsListResponseModel(
        message: json["message"],
        data:
            (json["data"] as List<dynamic>?)
                ?.map((x) => Patient.fromMap(x as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toMap() => {
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toMap())),
  };
}

// Model untuk respons saat berhasil menambahkan/mengoneksikan satu pasien
class SinglePatientResponseModel {
  final String? message;
  final Patient? data; // Data satu pasien yang baru dikoneksikan

  SinglePatientResponseModel({this.message, this.data});

  factory SinglePatientResponseModel.fromJson(String str) =>
      SinglePatientResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory SinglePatientResponseModel.fromMap(Map<String, dynamic> json) =>
      SinglePatientResponseModel(
        message: json["message"],
        data: json["data"] == null ? null : Patient.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {"message": message, "data": data?.toMap()};
}
