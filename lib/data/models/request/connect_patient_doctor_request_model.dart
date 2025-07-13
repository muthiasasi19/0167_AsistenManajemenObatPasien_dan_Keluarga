import 'dart:convert';

class ConnectPatientRequestModel {
  final String patientUniqueId; // ID unik pasien yang akan dikoneksikan
  final String doctorId; // ID dokter yang melakukan koneksi

  ConnectPatientRequestModel({
    required this.patientUniqueId,
    required this.doctorId,
  });

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
    "patientUniqueId":
        patientUniqueId, // Sesuaikan dengan kunci yang diharapkan backend
    "doctorId": doctorId, // Sesuaikan dengan kunci yang diharapkan backend
  };
}
