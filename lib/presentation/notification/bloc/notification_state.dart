part of 'notification_bloc.dart';

sealed class NotificationState {
  const NotificationState(); // Constructor konstan
}

final class NotificationInitial extends NotificationState {}

final class NotificationLoading extends NotificationState {}

/// State ketika jadwal notifikasi berhasil dimuat.
final class NotificationLoaded extends NotificationState {
  final List<NotificationScheduleData> schedules;

  const NotificationLoaded({required this.schedules}); // Tambah const
}

/// State ketika operasi (tambah/update/hapus) berhasil.
final class NotificationActionSuccess extends NotificationState {
  final String message;

  const NotificationActionSuccess({required this.message}); // Tambah const
}

/// State ketika terjadi kesalahan.
final class NotificationError extends NotificationState {
  final String message;

  const NotificationError({required this.message}); // Tambah const
}
