part of 'family_bloc.dart';

sealed class FamilyEvent {
  const FamilyEvent();
}

// Event untuk memuat data profil anggota keluarga yang sedang login
class LoadFamilyDataRequested extends FamilyEvent {
  const LoadFamilyDataRequested();
}

// Event untuk memuat daftar pasien yang terhubung dengan anggota keluarga
class LoadConnectedPatientsRequested extends FamilyEvent {
  // Menambahkan parameter ID keluarga
  final String? familyId; // id_keluarga (contoh: KLG...)
  //  Menambahkan parameter ID global keluarga (integer dari JWT payload)
  final int? familyGlobalId;

  // Memperbarui konstruktor untuk menerima parameter ID
  const LoadConnectedPatientsRequested({this.familyId, this.familyGlobalId});
}

// Event untuk menghubungkan anggota keluarga dengan pasien menggunakan kode unik
class ConnectPatientRequested extends FamilyEvent {
  final String patientUniqueId; // Kode unik pasien (id_pasien VARCHAR)
  //  Menambahkan parameter ID keluarga ke event ini juga
  final String? familyId; // id_keluarga
  //  Menambahkan parameter ID global keluarga ke event ini juga
  final int? familyGlobalId;

  //  Memperbarui konstruktor untuk menerima parameter ID
  const ConnectPatientRequested({
    required this.patientUniqueId,
    this.familyId,
    this.familyGlobalId,
  });
}
