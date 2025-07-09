part of 'medication_bloc.dart';

sealed class MedicationState {}

final class MedicationInitial extends MedicationState {}

final class MedicationLoading extends MedicationState {}

final class MedicationsLoaded extends MedicationState {
  final List<Medication> medications;
  MedicationsLoaded({required this.medications});
}

final class MedicationSessionsLoaded extends MedicationState {
  final List<TodaysMedicationSession> sessions;
  MedicationSessionsLoaded({required this.sessions});
}

final class MedicationHistoryLoaded extends MedicationState {
  final List<MedicationHistoryData> history;
  MedicationHistoryLoaded({required this.history});
}

final class MedicationActionSuccess extends MedicationState {
  final String message;
  final dynamic data;
  MedicationActionSuccess({required this.message, this.data});
}

final class MedicationError extends MedicationState {
  final String message;
  MedicationError({required this.message});
}
