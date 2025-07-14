part of 'in_app_reminder_bloc.dart';

sealed class InAppReminderState {
  const InAppReminderState();
}

final class InAppReminderInitial extends InAppReminderState {}

final class InAppReminderLoading extends InAppReminderState {}

/// State ketika jadwal pengingat berhasil dimuat.
/// Mengandung daftar jadwal pengingat yang akan dipantau oleh timer.
final class InAppReminderLoaded extends InAppReminderState {
  final List<NotificationScheduleData> schedules;

  const InAppReminderLoaded({required this.schedules});
}

/// State yang dipancarkan ketika ada pengingat yang perlu ditampilkan di UI.
final class ShowInAppReminder extends InAppReminderState {
  final String medicationName;
  final String medicationDosage;
  final String patientName;
  final String scheduledTime; // Waktu pengingat (HH:MM)
  final String reminderType; // "early" atau "on_time"

  const ShowInAppReminder({
    required this.medicationName,
    required this.medicationDosage,
    required this.patientName,
    required this.scheduledTime,
    required this.reminderType,
  });
}

/// State ketika terjadi kesalahan dalam memuat/memproses pengingat.
final class InAppReminderError extends InAppReminderState {
  final String message;

  const InAppReminderError({required this.message});
}
