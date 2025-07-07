part of 'patient_bloc.dart';

sealed class PatientEvent {
  const PatientEvent();
}

// Event ketika request untuk menghubungkan pasien dikirim
class ConnectPatientRequested extends PatientEvent {
  final String patientUniqueId; // ID unik pasien yang ingin dihubungkan

  const ConnectPatientRequested({required this.patientUniqueId});
}

// Event ketika request untuk memuat daftar pasien dikirim
class PatientsRequested extends PatientEvent {
  const PatientsRequested();
}

class SearchConnectedPatientsRequested extends PatientEvent {
  final String queryNama;

  const SearchConnectedPatientsRequested({required this.queryNama});

  List<Object> get props => [queryNama];
}

class GetConnectedDoctorRequested extends PatientEvent {
  const GetConnectedDoctorRequested();
}
