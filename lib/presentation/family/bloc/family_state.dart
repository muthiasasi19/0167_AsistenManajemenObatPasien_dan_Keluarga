part of 'family_bloc.dart';

// Kelas dasar untuk semua state Family
sealed class FamilyState {
  const FamilyState();
}

// State awal Family
final class FamilyInitial extends FamilyState {
  const FamilyInitial();
}

// State saat sedang memuat data utama keluarga atau pasien terhubung
final class FamilyLoading extends FamilyState {
  const FamilyLoading();
}

// State saat data utama keluarga berhasil dimuat
final class FamilyLoaded extends FamilyState {
  final User familyUserData; // Data profil anggota keluarga yang login
  const FamilyLoaded({required this.familyUserData});
}

// State saat terjadi error dalam memuat data utama keluarga atau pasien terhubung
final class FamilyError extends FamilyState {
  final String message;
  const FamilyError({required this.message});
}

//Profil family
final class FamilyProfileLoaded extends FamilyState {
  final FamilyData familyData; // Data profil anggota keluarga yang login
  const FamilyProfileLoaded({required this.familyData});
}

// State saat daftar pasien terhubung sedang dimuat
final class ConnectedPatientsLoading extends FamilyState {
  const ConnectedPatientsLoading();
}

// State saat daftar pasien terhubung berhasil dimuat
final class ConnectedPatientsLoaded extends FamilyState {
  final List<FamilyConnectedPatientData> patients;
  const ConnectedPatientsLoaded({required this.patients});
}

// State saat terjadi error dalam memuat daftar pasien terhubung
final class ConnectedPatientsError extends FamilyState {
  final String message;
  const ConnectedPatientsError({required this.message});
}

// State saat proses menghubungkan pasien sedang berlangsung
final class PatientConnecting extends FamilyState {
  const PatientConnecting();
}

// State saat pasien berhasil dihubungkan
final class PatientConnectionSuccess extends FamilyState {
  final String message;
  const PatientConnectionSuccess({required this.message});
}

// State saat gagal menghubungkan pasien
final class PatientConnectionFailure extends FamilyState {
  final String error;
  const PatientConnectionFailure({required this.error});
}

// State untuk lokasi pasien (jika diimplementasikan di sini)
// final class PatientLocationLoading extends FamilyState {
//   const PatientLocationLoading();
// }

// final class PatientLocationLoaded extends FamilyState {
//   final PatientLocationData locationData;
//   const PatientLocationLoaded({required this.locationData});
// }

// final class PatientLocationError extends FamilyState {
//   final String message;
//   const PatientLocationError({required this.message});
// }
