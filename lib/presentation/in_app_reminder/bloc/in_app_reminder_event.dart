part of 'in_app_reminder_bloc.dart';

sealed class InAppReminderEvent {
  const InAppReminderEvent();
}

/// Event untuk memuat semua jadwal pengingat yang relevan untuk pengguna saat ini (pasien/keluarga).
final class LoadMyNotificationSchedules extends InAppReminderEvent {
  const LoadMyNotificationSchedules();
}

/// Event yang dipicu secara berkala oleh timer untuk memeriksa jadwal pengingat.
final class CheckForInAppReminders extends InAppReminderEvent {
  const CheckForInAppReminders();
}
