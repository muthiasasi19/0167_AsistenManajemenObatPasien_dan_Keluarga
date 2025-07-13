part of 'patient_bloc.dart';

sealed class PatientState {
  // Kelas dasar untuk semua state pasien, mengimplementasikan Equatable
  const PatientState();

  // @override // Tidak perlu override jika Equatable tidak diimplementasikan secara langsung di sini
  List<Object> get props => []; // Implementasi default untuk Equatable
}

// State Awal (Initial)
final class PatientInitial extends PatientState {
  const PatientInitial();
}

// satte profil
final class PatientProfileLoaded extends PatientState {
  final Patient patientData; // Data profil pasien yang login
  const PatientProfileLoaded({required this.patientData});
}

// State Sedang Memuat (Loading)
final class PatientLoading extends PatientState {
  const PatientLoading();
}

// State Error
final class PatientError extends PatientState {
  final String message;
  const PatientError({required this.message});

  @override
  List<Object> get props => [message];
}

// State Daftar Pasien Berhasil Dimuat
final class PatientsLoaded extends PatientState {
  final List<Patient>
  patients; // Menggunakan model Patient dari patient_response_model.dart
  const PatientsLoaded({required this.patients});

  @override
  List<Object> get props => [patients];
}

// State Koneksi Pasien Berhasil
final class PatientConnectionSuccess extends PatientState {
  final String message;
  // Jika `connectedPatient` dari backend bisa berupa objek Patient,
  // maka lebih baik ubah dynamic menjadi Patient?
  // --- PERBAIKAN: Ubah dynamic menjadi Patient? jika model Patient digunakan di sini ---
  final Patient? connectedPatient;
  // --- AKHIR PERBAIKAN ---
  const PatientConnectionSuccess({
    required this.message,
    this.connectedPatient, // Ubah ke this.connectedPatient jika properti bisa null
  });

  @override
  List<Object> get props => [message, connectedPatient ?? '']; // Handle nullability
}

// State Hasil Pencarian Pasien Terhubung Berhasil Dimuat
final class ConnectedPatientsSearchLoaded extends PatientState {
  // Menggunakan model PatientSearchResult dari patient_response_model.dart
  final List<PatientSearchResult> searchResults;

  const ConnectedPatientsSearchLoaded({required this.searchResults});

  @override
  List<Object> get props => [searchResults];
}

// State Error Pencarian Pasien Terhubung
// --- PERBAIKAN: Pindahkan definisi kelas ini dari patient_bloc.dart ---
final class ConnectedPatientsSearchError extends PatientState {
  final String message;

  const ConnectedPatientsSearchError({required this.message});

  @override
  List<Object> get props => [message];
}

final class ConnectedDoctorLoading extends PatientState {
  const ConnectedDoctorLoading();
}

final class ConnectedDoctorLoaded extends PatientState {
  final DoctorData doctorData;
  const ConnectedDoctorLoaded({required this.doctorData});
  @override
  List<Object> get props => [doctorData];
}

final class ConnectedDoctorError extends PatientState {
  final String message;
  const ConnectedDoctorError({required this.message});
  @override
  List<Object> get props => [message];
}
