import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart'; // Untuk formatting waktu
import 'dart:async'; // Untuk Timer
import 'dart:developer' as developer;

import 'package:manajemen_obat/data/models/repository/notification_repository.dart';
import 'package:manajemen_obat/data/models/response/notification_schedule_response_model.dart';

part 'in_app_reminder_event.dart';
part 'in_app_reminder_state.dart';

class InAppReminderBloc extends Bloc<InAppReminderEvent, InAppReminderState> {
  final NotificationRepository notificationRepository;
  List<NotificationScheduleData> _currentSchedules = []; // Cache jadwal aktif
  Set<int> _triggeredRemindersToday =
      {}; // Melacak pengingat yang sudah dipicu hari ini

  InAppReminderBloc({required this.notificationRepository})
    : super(InAppReminderInitial()) {
    on<LoadMyNotificationSchedules>(_onLoadMyNotificationSchedules);
    on<CheckForInAppReminders>(_onCheckForInAppReminders);
  }

  Future<void> _onLoadMyNotificationSchedules(
    LoadMyNotificationSchedules event,
    Emitter<InAppReminderState> emit,
  ) async {
    emit(InAppReminderLoading());
    final result = await notificationRepository.fetchMyNotificationSchedules();
    result.fold(
      (l) {
        developer.log("InAppReminderBloc: Load Error: $l");
        emit(InAppReminderError(message: l));
      },
      (r) {
        developer.log(
          "InAppReminderBloc: Load Success: ${r.length} schedules loaded.",
        );
        _currentSchedules = r;
        // Reset triggered reminders for a new load (e.g., app restart)
        _triggeredRemindersToday = {};
        emit(InAppReminderLoaded(schedules: _currentSchedules));
      },
    );
  }

  Future<void> _onCheckForInAppReminders(
    CheckForInAppReminders event,
    Emitter<InAppReminderState> emit,
  ) async {
    if (_currentSchedules.isEmpty) {
      developer.log("InAppReminderBloc: No schedules to check.");
      return; // Tidak ada jadwal untuk diperiksa
    }

    final now = DateTime.now();
    DateFormat('yyyy-MM-dd').format(now);
    final currentTimeMinutes = now.hour * 60 + now.minute;

    for (var schedule in _currentSchedules) {
      // Pastikan jadwal aktif dan dalam rentang tanggal
      bool isActiveToday =
          schedule.isActive &&
          (now.isAfter(schedule.startDate) ||
              now.isAtSameMomentAs(schedule.startDate)) &&
          (schedule.endDate == null ||
              (now.isBefore(schedule.endDate!) ||
                  now.isAtSameMomentAs(schedule.endDate!)));

      if (!isActiveToday) continue;

      // Konversi scheduleTime (HH:MM) ke menit
      final parts = schedule.scheduleTime.split(':');
      if (parts.length != 2) {
        developer.log(
          "InAppReminderBloc: Invalid scheduleTime format for ID ${schedule.id}: ${schedule.scheduleTime}",
        );
        continue;
      }
      final scheduledHour = int.tryParse(parts[0]);
      final scheduledMinute = int.tryParse(parts[1]);

      if (scheduledHour == null || scheduledMinute == null) {
        developer.log(
          "InAppReminderBloc: Could not parse scheduleTime for ID ${schedule.id}: ${schedule.scheduleTime}",
        );
        continue;
      }

      final scheduledTimeMinutes = scheduledHour * 60 + scheduledMinute;

      // 1. Pengingat Awal (misal: 5 menit sebelum)
      const int earlyReminderOffsetMinutes = 5;
      final int earlyTriggerTimeMinutes =
          scheduledTimeMinutes - earlyReminderOffsetMinutes;

      // Cek apakah waktu saat ini berada dalam jendela pengingat awal
      if (currentTimeMinutes >= earlyTriggerTimeMinutes &&
          currentTimeMinutes < scheduledTimeMinutes &&
          !_triggeredRemindersToday.contains(
            schedule.id * 1000 + earlyTriggerTimeMinutes,
          )) {
        // Tambahkan offset unik untuk early reminder
        developer.log(
          "InAppReminderBloc: Triggering early reminder for ID ${schedule.id} at ${schedule.scheduleTime}",
        );
        emit(
          ShowInAppReminder(
            medicationName: schedule.medicationName ?? 'Obat',
            medicationDosage: schedule.medicationDosage ?? '',
            patientName: schedule.patientName ?? 'Anda',
            scheduledTime: schedule.scheduleTime,
            reminderType: 'early',
          ),
        );
        _triggeredRemindersToday.add(
          schedule.id * 1000 + earlyTriggerTimeMinutes,
        ); // Tandai sudah dipicu
      }

      // 2. Pengingat Tepat Waktu
      // Biarkan ada sedikit jendela waktu agar pengingat tidak terlewat jika pengguna membuka aplikasi pas di detik 00
      const int onTimeWindowMinutes = 1; // 1 menit setelah waktu terjadwal
      if (currentTimeMinutes >= scheduledTimeMinutes &&
          currentTimeMinutes < scheduledTimeMinutes + onTimeWindowMinutes &&
          !_triggeredRemindersToday.contains(schedule.id)) {
        // Gunakan ID saja untuk on-time reminder
        developer.log(
          "InAppReminderBloc: Triggering on-time reminder for ID ${schedule.id} at ${schedule.scheduleTime}",
        );
        emit(
          ShowInAppReminder(
            medicationName: schedule.medicationName ?? 'Obat',
            medicationDosage: schedule.medicationDosage ?? '',
            patientName: schedule.patientName ?? 'Anda',
            scheduledTime: schedule.scheduleTime,
            reminderType: 'on_time',
          ),
        );
        _triggeredRemindersToday.add(schedule.id); // Tandai sudah dipicu
      }
    }
  }

  @override
  Future<void> close() {
    // Clear triggered reminders when the BLoC is closed
    _triggeredRemindersToday.clear();
    return super.close();
  }
}
