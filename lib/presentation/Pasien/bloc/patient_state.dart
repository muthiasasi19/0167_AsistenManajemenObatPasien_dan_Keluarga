part of 'patient_bloc.dart'; // Penting: Pastikan ini benar

// Menandakan bahwa class ini imutable
sealed class PatientState {
  // Kelas dasar untuk semua state pasien
  const PatientState();
  // Tidak perlu List<Object> get props jika Equatable tidak digunakan
  // Jadi baris `List<Object> get props => [];` di sini TIDAK ADA.
}

// State Awal (Initial)
final class PatientInitial extends PatientState {
  const PatientInitial();
}

// State sedang dalam proses koneksi
final class PatientConnecting extends PatientState {
  const PatientConnecting();
}

// State profil pasien berhasil dimuat
final class PatientProfileLoaded extends PatientState {
  final Patient patientData; // Data profil pasien yang login
  const PatientProfileLoaded({required this.patientData});
  // Tidak perlu override get props
}

// State Sedang Memuat (Loading)
final class PatientLoading extends PatientState {
  const PatientLoading();
}

// State Error
final class PatientError extends PatientState {
  final String message;
  const PatientError({required this.message});
  // Tidak perlu override get props
}

// State Daftar Pasien Berhasil Dimuat
final class PatientsLoaded extends PatientState {
  final List<Patient>
  patients; // Menggunakan model Patient dari patient_response_model.dart
  const PatientsLoaded({required this.patients});
  // Tidak perlu override get props
}

// State Koneksi Pasien Berhasil
final class PatientConnectionSuccess extends PatientState {
  final String message;
  final Patient? connectedPatient;
  const PatientConnectionSuccess({
    required this.message,
    this.connectedPatient,
  });
  // Tidak perlu override get props
}

// State Hasil Pencarian Pasien Terhubung Berhasil Dimuat
final class ConnectedPatientsSearchLoaded extends PatientState {
  // Menggunakan model PatientSearchResult dari patient_response_model.dart
  final List<PatientSearchResult> searchResults;

  const ConnectedPatientsSearchLoaded({required this.searchResults});
  // Tidak perlu override get props
}

// State Error Pencarian Pasien Terhubung
final class ConnectedPatientsSearchError extends PatientState {
  final String message;

  const ConnectedPatientsSearchError({required this.message});
  // Tidak perlu override get props
}

final class ConnectedDoctorLoading extends PatientState {
  const ConnectedDoctorLoading();
}

final class ConnectedDoctorLoaded extends PatientState {
  final DoctorData doctorData;
  const ConnectedDoctorLoaded({required this.doctorData});
  // Tidak perlu override get props
}

final class ConnectedDoctorError extends PatientState {
  final String message;
  const ConnectedDoctorError({required this.message});
  // Tidak perlu override get props
}

// // FITUR MAPS: State untuk menunjukkan lokasi berhasil dikirim
// final class PatientLocationSentSuccess extends PatientState {
//   final String message;
//   const PatientLocationSentSuccess(this.message);
//   // Tidak perlu override get props
// }

// FITUR MAPS: State untuk menunjukkan lokasi gagal dikirim
// final class PatientLocationSentFailure extends PatientState {
//   // KOREKSI FINAL: Menggunakan named parameter `required this.error`
//   final String error;
//   const PatientLocationSentFailure({
//     required this.error,
//   }); // <-- PERBAIKAN DI SINI
// }
// // AKHIR MAPS
