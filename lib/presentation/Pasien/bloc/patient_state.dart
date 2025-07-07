part of 'patient_bloc.dart';

sealed class PatientState {
  const PatientState();

  List<Object> get props => [];
}

// State Awal (Initial)
final class PatientInitial extends PatientState {
  const PatientInitial();
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
  final Patient? connectedPatient;
  const PatientConnectionSuccess({
    required this.message,
    this.connectedPatient,
  });

  @override
  List<Object> get props => [message, connectedPatient ?? '']; // Handle nullability
}

// State Hasil Pencarian Pasien Terhubung Berhasil Dimuat
final class ConnectedPatientsSearchLoaded extends PatientState {
  final List<PatientSearchResult> searchResults;

  const ConnectedPatientsSearchLoaded({required this.searchResults});

  @override
  List<Object> get props => [searchResults];
}

// State Error Pencarian Pasien Terhubung
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
