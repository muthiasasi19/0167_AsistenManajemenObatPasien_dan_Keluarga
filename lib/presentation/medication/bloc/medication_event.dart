part of 'medication_bloc.dart';

sealed class MedicationEvent {
  const MedicationEvent();
}

class GetMedicationsRequested extends MedicationEvent {
  final String? patientUniqueId;
  final int? patientGlobalId;
  final bool isForPatientOrFamilyToday;
  final bool isForDoctorScheduled;
  const GetMedicationsRequested({
    this.patientUniqueId,

    this.patientGlobalId,

    this.isForPatientOrFamilyToday = false,

    this.isForDoctorScheduled = false,
  }) : assert(
         patientUniqueId != null || patientGlobalId != null,

         'patientUniqueId or patientGlobalId must be provided for GetMedicationsRequested',
       );
}

class GetMedicationHistoryRequested extends MedicationEvent {
  final String? patientUniqueId;
  final int? patientGlobalId;

  const GetMedicationHistoryRequested({
    this.patientUniqueId,
    this.patientGlobalId,
  }) : assert(
         patientUniqueId != null || patientGlobalId != null,
         'patientUniqueId or patientGlobalId must be provided for GetMedicationHistoryRequested',
       );
}

class AddMedicationRequested extends MedicationEvent {
  final String? patientUniqueId;
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

  const UpdateMedicationRequested({
    required this.medicationId,
    required this.request,
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
