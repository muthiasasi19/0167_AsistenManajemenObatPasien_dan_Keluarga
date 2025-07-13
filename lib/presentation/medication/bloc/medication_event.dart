part of 'medication_bloc.dart';

sealed class MedicationEvent {
  const MedicationEvent();
}

class GetMedicationsRequested extends MedicationEvent {
  final String? patientUniqueId;
  final int?
  patientGlobalId; // Tetap sertakan jika memang ada niat untuk digunakan di masa depan/logging
  final bool isForPatientOrFamilyToday;
  final bool isForDoctorScheduled;
  const GetMedicationsRequested({
    this.patientUniqueId,

    this.patientGlobalId,

    this.isForPatientOrFamilyToday = false, // Default false

    this.isForDoctorScheduled = false, // Default false
  }) : assert(
         patientUniqueId != null || patientGlobalId != null,

         'patientUniqueId or patientGlobalId must be provided for GetMedicationsRequested',
       );
}

class GetMedicationHistoryRequested extends MedicationEvent {
  // Sama seperti GetMedicationsRequested, repository saat ini hanya memanfaatkan patientUniqueId
  // (atau currentUser.idPasien).
  final String? patientUniqueId;
  final int? patientGlobalId; // Tetap sertakan

  const GetMedicationHistoryRequested({
    this.patientUniqueId,
    this.patientGlobalId,
  }) : assert(
         patientUniqueId != null || patientGlobalId != null,
         'patientUniqueId or patientGlobalId must be provided for GetMedicationHistoryRequested',
       );

  // Jika Anda menggunakan equatable, tambahkan props
  // @override
  // List<Object?> get props => [patientUniqueId, patientGlobalId];
}

class AddMedicationRequested extends MedicationEvent {
  final String? patientUniqueId; // Untuk dokter (jika menambah via unique ID)
  final int? patientGlobalId;
  final AddMedicationRequestModel request;
  final File? photoFile;

  const AddMedicationRequested({
    this.patientUniqueId,
    this.patientGlobalId,
    this.photoFile,
    required this.request,
  }) : assert(
         patientUniqueId != null || patientGlobalId != null,
         'patientUniqueId or patientGlobalId must be provided for AddMedicationRequested',
       );
}

class UpdateMedicationRequested extends MedicationEvent {
  final int medicationId;
  final UpdateMedicationRequestModel request;
  final File? photoFile;
  final String? existingPhotoUrl;

  const UpdateMedicationRequested({
    required this.medicationId,
    required this.request,
    this.photoFile,
    this.existingPhotoUrl,
  });
}

class DeleteMedicationRequested extends MedicationEvent {
  final int medicationId;

  const DeleteMedicationRequested({required this.medicationId});
}

class MedicationClearRequested extends MedicationEvent {
  const MedicationClearRequested();
}

class MarkMedicationAsTakenRequested extends MedicationEvent {
  final int medicationId;
  final bool isTaken;
  final String? scheduledTime;
  final String? notes;

  const MarkMedicationAsTakenRequested({
    required this.medicationId,
    required this.isTaken,
    this.scheduledTime,
    this.notes,
  });
}
