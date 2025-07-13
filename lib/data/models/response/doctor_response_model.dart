// lib/data/models/response/doctor_response_model.dart

class DoctorData {
  final String idDokter; // Ini adalah ID unik dokter (misal: DOKxxxx)
  final String name;
  final String specialization;
  final String phoneNumber;

  DoctorData({
    required this.idDokter,
    required this.name,
    required this.specialization,
    required this.phoneNumber,
  });

  // Factory constructor untuk membuat instance DoctorData dari JSON (Map)
  factory DoctorData.fromJson(Map<String, dynamic> json) {
    return DoctorData(
      idDokter:
          json['id_dokter'] ??
          '', // Sesuaikan kunci dengan response backend Anda
      name: json['nama'] ?? 'Nama Dokter Tidak Diketahui',
      specialization: json['specialization'] ?? 'Spesialisasi Tidak Tersedia',
      phoneNumber: json['nomor_telepon'] ?? 'Tidak Tersedia',
    );
  }

  // Metode untuk mengonversi instance DoctorData kembali ke Map (jika diperlukan untuk pengiriman data)
  Map<String, dynamic> toJson() {
    return {
      'id_dokter': idDokter,
      'nama': name,
      'specialization': specialization,
      'nomor_telepon': phoneNumber,
    };
  }
}
