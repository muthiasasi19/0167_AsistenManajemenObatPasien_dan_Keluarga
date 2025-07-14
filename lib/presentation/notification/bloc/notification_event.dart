part of 'notification_bloc.dart';

sealed class NotificationEvent {
  const NotificationEvent(); // Constructor konstan
}

/// Event untuk memuat jadwal notifikasi untuk obat dan pasien tertentu.
final class LoadNotificationSchedulesForMedicationAndPatient
    extends NotificationEvent {
  final int medicationGlobalId;
  final int patientGlobalId;

  const LoadNotificationSchedulesForMedicationAndPatient({
    required this.medicationGlobalId,
    required this.patientGlobalId,
  });
}

/// Event untuk menambah jadwal notifikasi baru.
final class AddNotificationSchedule extends NotificationEvent {
  final AddNotificationScheduleRequestModel request;

  const AddNotificationSchedule({required this.request});
}

/// Event untuk memperbarui jadwal notifikasi yang sudah ada.
final class UpdateNotificationSchedule extends NotificationEvent {
  final int scheduleId;
  final UpdateNotificationScheduleRequestModel request;

  const UpdateNotificationSchedule({
    required this.scheduleId,
    required this.request,
  });
}

/// Event untuk menghapus jadwal notifikasi.
final class DeleteNotificationSchedule extends NotificationEvent {
  final int scheduleId;
  final int medicationGlobalId; // TAMBAH INI UNTUK KONSISTENSI
  final int patientGlobalId; // TAMBAH INI UNTUK KONSISTENSI

  const DeleteNotificationSchedule({
    required this.scheduleId,
    required this.medicationGlobalId, // TAMBAH INI UNTUK KONSISTENSI
    required this.patientGlobalId, // TAMBAH INI UNTUK KONSISTENSI
  });
}
