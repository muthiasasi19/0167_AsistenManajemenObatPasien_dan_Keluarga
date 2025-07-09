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
  final String? familyId;
  final int? familyGlobalId;

  const LoadConnectedPatientsRequested({this.familyId, this.familyGlobalId});
}

// Event untuk menghubungkan anggota keluarga dengan pasien menggunakan kode unik
class ConnectPatientRequested extends FamilyEvent {
  final String patientUniqueId;
  final String? familyId;

  const ConnectPatientRequested({
    required this.patientUniqueId,
    this.familyId,
    this.familyGlobalId,
  });
}
