import 'dart:convert';

class FamilyConnectRequestModel {
  // Ini adalah properti yang akan dikirim ke backend
  final String patientUniqueId;

  FamilyConnectRequestModel({required this.patientUniqueId});

  // Metode untuk mengkonversi objek menjadi String JSON
  String toJson() => json.encode(toMap());

  // Metode untuk mengkonversi objek menjadi Map<String, dynamic>
  Map<String, dynamic> toMap() => {"patientUniqueId": patientUniqueId};
}
