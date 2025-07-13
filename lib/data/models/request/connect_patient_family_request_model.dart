import 'dart:convert';

class FamilyConnectRequestModel {
  // Ini adalah properti yang akan dikirim ke backend
  final String patientUniqueId;

  FamilyConnectRequestModel({
    required this.patientUniqueId, // HANYA parameter ini yang diperlukan!
  });

  // Metode untuk mengkonversi objek menjadi String JSON
  String toJson() => json.encode(toMap());

  // Metode untuk mengkonversi objek menjadi Map<String, dynamic>
  Map<String, dynamic> toMap() => {
    // Nama kunci ini harus sesuai dengan yang diharapkan oleh backend di `req.body`
    "patientUniqueId": patientUniqueId,
  };
}
