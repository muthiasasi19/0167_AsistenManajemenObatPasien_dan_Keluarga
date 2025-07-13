// lib/bloc/doctor/doctor_state.dart
part of 'doctor_bloc.dart';

sealed class DoctorState {
  const DoctorState();
}

// State Awal
final class DoctorInitial extends DoctorState {
  const DoctorInitial();
}

// State Sedang Memuat Data/Melakukan Operasi
final class DoctorLoading extends DoctorState {
  final String?
  message; // Optional message for loading state (e.g., "Mencari pasien...")
  const DoctorLoading({this.message});
}

// State Ketika Terjadi Error
final class DoctorError extends DoctorState {
  final String message;
  const DoctorError({required this.message});
}

// State Ketika Profil Dokter Berhasil Dimuat
final class DoctorProfileLoaded extends DoctorState {
  final DoctorData doctorData;
  const DoctorProfileLoaded({required this.doctorData});
}

// State Ketika Daftar Pasien Terhubung Berhasil Dimuat
final class DoctorConnectedPatientsLoaded extends DoctorState {
  final List<Patient> patients;
  const DoctorConnectedPatientsLoaded({required this.patients});
}

// State Ketika Operasi Koneksi/Diskoneksi Pasien Berhasil
final class DoctorPatientConnectionSuccess extends DoctorState {
  final String message;
  const DoctorPatientConnectionSuccess({required this.message});
}

// State Ketika Operasi CRUD Obat Berhasil
final class DoctorMedicationActionSuccess extends DoctorState {
  final String message;
  const DoctorMedicationActionSuccess({required this.message});
}

// State Ketika Daftar Obat Pasien Berhasil Dimuat
final class DoctorPatientMedicationsLoaded extends DoctorState {
  final List<Medication> medications;
  const DoctorPatientMedicationsLoaded({required this.medications});
}

// State Ketika Riwayat Konsumsi Obat Pasien Berhasil Dimuat
final class DoctorPatientMedicationHistoryLoaded extends DoctorState {
  final List<MedicationHistoryData> // UBAH TIPE DATA INI!
  medicationHistory;
  const DoctorPatientMedicationHistoryLoaded({required this.medicationHistory});
}
