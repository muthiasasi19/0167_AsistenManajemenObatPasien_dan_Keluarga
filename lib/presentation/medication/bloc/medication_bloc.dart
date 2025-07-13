import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:manajemen_obat/data/models/repository/medication_repository.dart';
import 'package:manajemen_obat/data/models/request/medication/add_medication_request_model.dart';
import 'package:manajemen_obat/data/models/request/medication/update_medication_request_model.dart';
import 'package:manajemen_obat/data/models/response/medication_history_response_model.dart';
import 'package:manajemen_obat/data/models/response/medication_response_model.dart';
import 'dart:developer';

part 'medication_event.dart';
part 'medication_state.dart';

class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final MedicationRepository medicationRepository;

  MedicationBloc({required this.medicationRepository})
    : super(MedicationInitial()) {
    on<GetMedicationsRequested>(_onGetMedicationsRequested);
    on<GetMedicationHistoryRequested>(_onGetMedicationHistoryRequested);
    on<AddMedicationRequested>(_onAddMedicationRequested);
    on<UpdateMedicationRequested>(_onUpdateMedicationsRequested);
    on<DeleteMedicationRequested>(_onDeleteMedicationRequested);
    on<MedicationClearRequested>(_onMedicationClearRequested);
    on<MarkMedicationAsTakenRequested>(_onMarkMedicationAsTakenRequested);
  }

  Future<void> _onGetMedicationsRequested(
    GetMedicationsRequested event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());
    // Logika untuk membedakan antara dokter (medications) dan pasien/keluarga (sessions)
    if (event.isForPatientOrFamilyToday) {
      final result = await medicationRepository.getTodaysMedicationSessions(
        patientGlobalId: event.patientGlobalId,
        patientUniqueId: event.patientUniqueId,
      );
      result.fold(
        (l) => emit(MedicationError(message: l)),
        (r) => emit(
          MedicationSessionsLoaded(sessions: r.data),
        ), // Menggunakan MedicationSessionsLoaded
      );
    } else {
      final result = await medicationRepository.getMedicationsByPatientId(
        patientGlobalId: event.patientGlobalId,
        patientUniqueId: event.patientUniqueId,
      );
      result.fold(
        (l) => emit(MedicationError(message: l)),
        (r) => emit(
          MedicationsLoaded(medications: r.data),
        ), // Menggunakan MedicationsLoaded
      );
    }
  }

  Future<void> _onGetMedicationHistoryRequested(
    GetMedicationHistoryRequested event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());
    // Mengubah emit state menjadi MedicationHistoryLoaded untuk tipe data yang benar
    final result = await medicationRepository.getMedicationHistoryByPatientId(
      patientGlobalId: event.patientGlobalId,
      patientUniqueId: event.patientUniqueId,
    );
    result.fold(
      (l) => emit(MedicationError(message: l)),
      (r) => emit(
        MedicationHistoryLoaded(
          history: r.data,
        ), // Hapus .cast<MedicationHistoryData>()
      ),
    );
  }

  Future<void> _onAddMedicationRequested(
    AddMedicationRequested event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());

    if (event.patientUniqueId == null || event.patientUniqueId!.isEmpty) {
      emit(
        MedicationError(
          message:
              "Patient Unique ID tidak boleh kosong saat menambahkan obat.",
        ),
      );
      return;
    }

    final result = await medicationRepository.addMedication(
      event.patientUniqueId!,
      event.request.copyWith(
        photoFile: event.photoFile,
      ), // Teruskan photoFile ke repository
    );

    result.fold(
      (l) {
        log("MedicationBloc: AddMedication Error: $l");
        emit(MedicationError(message: l));
      },
      (r) {
        log("MedicationBloc: AddMedication Success: ${r.message}");
        emit(
          MedicationActionSuccess(
            message: r.message ?? 'Obat berhasil ditambahkan!',
            data: r.data,
          ),
        );
      },
    );
  }

  Future<void> _onUpdateMedicationsRequested(
    UpdateMedicationRequested event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());

    final result = await medicationRepository.updateMedication(
      event.medicationId,
      event.request.copyWith(
        photoFile: event.photoFile,
        photoUrl: event.existingPhotoUrl, // Sertakan URL foto yang sudah ada
      ),
    );

    result.fold(
      (l) {
        log("MedicationBloc: UpdateMedication Error: $l");
        emit(MedicationError(message: l));
      },
      (r) {
        log("MedicationBloc: UpdateMedication Success: ${r.message}");
        emit(
          MedicationActionSuccess(
            message: r.message ?? 'Obat berhasil diperbarui!',
            data: r.data,
          ),
        );
      },
    );
  }

  Future<void> _onDeleteMedicationRequested(
    DeleteMedicationRequested event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());

    final result = await medicationRepository.deleteMedication(
      event.medicationId,
    );

    result.fold(
      (l) {
        log("MedicationBloc: DeleteMedication Error: $l");
        emit(MedicationError(message: l));
      },
      (r) {
        log("MedicationBloc: DeleteMedication Success: $r");
        emit(MedicationActionSuccess(message: r));
      },
    );
  }

  void _onMedicationClearRequested(
    MedicationClearRequested event,
    Emitter<MedicationState> emit,
  ) {
    emit(MedicationsLoaded(medications: []));
  }

  Future<void> _onMarkMedicationAsTakenRequested(
    MarkMedicationAsTakenRequested event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());
    try {
      final String statusToSend =
          event.isTaken
              ? 'taken'
              : 'pending'; // Jika isTaken false, berarti undo (set ke 'pending')

      final markResult = await medicationRepository.markMedicationConsumption(
        event.medicationId,
        statusToSend, // Menggunakan status yang sudah ditentukan
        event.scheduledTime,
        event.notes,
      );

      markResult.fold(
        (l) {
          log("MedicationBloc: MarkMedication Error: $l");
          emit(MedicationError(message: l));
        },
        (r) {
          log("MedicationBloc: MarkMedication Success: $r");
          emit(
            MedicationActionSuccess(
              message: 'Status obat berhasil diperbarui!',
              data: null,
            ),
          );
        },
      );
    } catch (e) {
      log("MedicationBloc: Exception marking medication as taken: $e");
      emit(MedicationError(message: 'Gagal memperbarui status obat: $e'));
    }
  }
}
