import 'package:bloc/bloc.dart';
import 'package:manajemen_obat/data/models/repository/notification_repository.dart';
import 'package:manajemen_obat/data/models/request/notification/add_notification_schedule_request_model.dart';
import 'package:manajemen_obat/data/models/request/notification/update_notification_schedule_request_model.dart';
import 'package:manajemen_obat/data/models/response/notification_schedule_response_model.dart';
import 'dart:developer';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationBloc({required this.notificationRepository})
    : super(NotificationInitial()) {
    on<LoadNotificationSchedulesForMedicationAndPatient>(
      _onLoadNotificationSchedulesForMedicationAndPatient,
    );
    on<AddNotificationSchedule>(_onAddNotificationSchedule);
    on<UpdateNotificationSchedule>(_onUpdateNotificationSchedule);
    on<DeleteNotificationSchedule>(_onDeleteNotificationSchedule);
  }

  Future<void> _onLoadNotificationSchedulesForMedicationAndPatient(
    LoadNotificationSchedulesForMedicationAndPatient event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await notificationRepository
        .fetchNotificationSchedulesForMedicationAndPatient(
          medicationGlobalId: event.medicationGlobalId,
          patientGlobalId: event.patientGlobalId,
        );
    result.fold(
      (l) {
        log("NotificationBloc: Load Error: $l");
        emit(NotificationError(message: l));
      },
      (r) {
        log("NotificationBloc: Load Success: ${r.length} schedules loaded.");
        emit(NotificationLoaded(schedules: r));
      },
    );
  }

  Future<void> _onAddNotificationSchedule(
    AddNotificationSchedule event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await notificationRepository.addNotificationSchedule(
      event.request,
    );
    result.fold(
      (l) {
        log("NotificationBloc: Add Error: $l");
        emit(NotificationError(message: l));
      },
      (r) {
        log("NotificationBloc: Add Success: ${r.id}");
        emit(
          NotificationActionSuccess(
            message: 'Jadwal pengingat berhasil ditambahkan!',
          ),
        );
        // Setelah sukses, muat ulang jadwal untuk memperbarui UI
        emit(NotificationLoading()); // Emit loading sebelum memuat ulang
        add(
          LoadNotificationSchedulesForMedicationAndPatient(
            medicationGlobalId: event.request.medicationId,
            patientGlobalId: event.request.patientGlobalId,
          ),
        );
      },
    );
  }

  Future<void> _onUpdateNotificationSchedule(
    UpdateNotificationSchedule event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await notificationRepository.updateNotificationSchedule(
      event.scheduleId,
      event.request,
    );
    result.fold(
      (l) {
        log("NotificationBloc: Update Error: $l");
        emit(NotificationError(message: l));
      },
      (r) {
        log("NotificationBloc: Update Success: ${r.id}");
        emit(
          NotificationActionSuccess(
            message: 'Jadwal pengingat berhasil diperbarui!',
          ),
        );
        // Setelah sukses, muat ulang jadwal untuk memperbarui UI
        emit(NotificationLoading()); // Emit loading sebelum memuat ulang
        add(
          LoadNotificationSchedulesForMedicationAndPatient(
            medicationGlobalId:
                r.medicationId, // Ambil ID obat dari data yang diperbarui
            patientGlobalId:
                r.patientId, // Ambil ID pasien dari data yang diperbarui
          ),
        );
      },
    );
  }

  Future<void> _onDeleteNotificationSchedule(
    DeleteNotificationSchedule event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await notificationRepository.deleteNotificationSchedule(
      event.scheduleId,
    );
    result.fold(
      (l) {
        log("NotificationBloc: Delete Error: $l");
        emit(NotificationError(message: l));
      },
      (r) {
        log("NotificationBloc: Delete Success: $r");
        emit(NotificationActionSuccess(message: r));
        // Setelah sukses, muat ulang jadwal untuk memperbarui UI
        emit(NotificationLoading());
        add(
          LoadNotificationSchedulesForMedicationAndPatient(
            medicationGlobalId:
                event.medicationGlobalId, // Gunakan ID dari event
            patientGlobalId: event.patientGlobalId, // Gunakan ID dari event
          ),
        );
      },
    );
  }
}
