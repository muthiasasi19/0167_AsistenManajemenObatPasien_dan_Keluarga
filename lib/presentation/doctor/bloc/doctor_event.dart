part of 'doctor_bloc.dart';

sealed class DoctorEvent {
  const DoctorEvent();
}

// Event untuk memuat data profil dokter yang sedang login
class LoadDoctorProfileRequested extends DoctorEvent {
  const LoadDoctorProfileRequested();
}

// Event untuk memuat daftar pasien yang terhubung dengan dokter ini
class LoadConnectedPatientsRequested extends DoctorEvent {
  const LoadConnectedPatientsRequested();
}

// Event untuk menghubungkan pasien baru (oleh dokter)
class ConnectPatientRequested extends DoctorEvent {
  final String patientUniqueId;
  const ConnectPatientRequested({required this.patientUniqueId});
}

// Event untuk memutuskan koneksi pasien (oleh dokter)
class DisconnectPatientRequested extends DoctorEvent {
  final String patientUniqueId;
  const DisconnectPatientRequested({required this.patientUniqueId});
}

// Event untuk menambahkan obat untuk pasien tertentu (oleh dokter)
class AddMedicationRequested extends DoctorEvent {
  final String patientUniqueId;
  final AddMedicationRequestModel request;
  const AddMedicationRequested({
    required this.patientUniqueId,
    required this.request,
  });
}

// Event untuk memperbarui obat yang sudah ada (oleh dokter)
class UpdateMedicationRequested extends DoctorEvent {
  final int medicationId;
  final UpdateMedicationRequestModel request;
  const UpdateMedicationRequested({
    required this.medicationId,
    required this.request,
  });
}

// Event untuk menghapus obat (oleh dokter)
class DeleteMedicationRequested extends DoctorEvent {
  final int medicationId;
  const DeleteMedicationRequested({required this.medicationId});
}

// Event untuk memuat daftar obat (resep) untuk pasien tertentu (oleh dokter)
class ViewPatientMedicationsRequested extends DoctorEvent {
  final String patientUniqueId;
  final int patientGlobalId;

  const ViewPatientMedicationsRequested({
    required this.patientUniqueId,
    required this.patientGlobalId,
  });
}

// Event untuk memuat riwayat konsumsi obat pasien tertentu (oleh dokter)
class ViewPatientMedicationHistoryRequested extends DoctorEvent {
  final String patientUniqueId;
  final int patientGlobalId;

  const ViewPatientMedicationHistoryRequested({
    required this.patientUniqueId,
    required this.patientGlobalId,
  });
}
