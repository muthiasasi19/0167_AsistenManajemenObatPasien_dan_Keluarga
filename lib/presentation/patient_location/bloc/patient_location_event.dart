part of 'patient_location_bloc.dart'; // Penting: Pastikan ini benar

sealed class PatientLocationEvent {
  const PatientLocationEvent();
}

// Event untuk memuat lokasi pasien
class LoadPatientLocationRequested extends PatientLocationEvent {
  final int patientGlobalId;

  const LoadPatientLocationRequested({required this.patientGlobalId});

  // Tidak perlu override props karena tidak pakai Equatable
  // String toString() => 'LoadPatientLocationRequested { patientGlobalId: $patientGlobalId }';
}

class SendPatientLocationRequested extends PatientLocationEvent {
  final double latitude;
  final double longitude;

  const SendPatientLocationRequested({
    required this.latitude,
    required this.longitude,
  });
}
