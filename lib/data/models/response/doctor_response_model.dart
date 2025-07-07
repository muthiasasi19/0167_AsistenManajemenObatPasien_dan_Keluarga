class DoctorData {
  final String idDokter;
  final String name;
  final String specialization;
  final String phoneNumber;

  DoctorData({
    required this.idDokter,
    required this.name,
    required this.specialization,
    required this.phoneNumber,
  });

  factory DoctorData.fromJson(Map<String, dynamic> json) {
    return DoctorData(
      idDokter: json['id_dokter'] ?? '',
      name: json['nama'] ?? 'Nama Dokter Tidak Diketahui',
      specialization: json['specialization'] ?? 'Spesialisasi Tidak Tersedia',
      phoneNumber: json['nomor_telepon'] ?? 'Tidak Tersedia',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_dokter': idDokter,
      'nama': name,
      'specialization': specialization,
      'nomor_telepon': phoneNumber,
    };
  }
}
