// lib/bloc/doctor/doctor_bloc.dart
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:manajemen_obat/data/models/repository/doctor_repository.dart';
import 'package:manajemen_obat/data/models/repository/medication_repository.dart';
import 'package:manajemen_obat/data/models/request/medication/add_medication_request_model.dart';
import 'package:manajemen_obat/data/models/request/medication/update_medication_request_model.dart';
import 'package:manajemen_obat/data/models/response/doctor_response_model.dart';
import 'package:manajemen_obat/data/models/response/medication_response_model.dart';
import 'package:manajemen_obat/data/models/response/patient_response_model.dart';
import 'package:manajemen_obat/data/models/response/medication_history_response_model.dart';

part 'doctor_event.dart';
part 'doctor_state.dart';

class DoctorBloc extends Bloc<DoctorEvent, DoctorState> {
  final DoctorRepository doctorRepository;
  final MedicationRepository
  medicationRepository; // Dokter juga berinteraksi dengan obat

  DoctorBloc({
    required this.doctorRepository,
    required this.medicationRepository,
  }) : super(const DoctorInitial()) {
    on<LoadDoctorProfileRequested>(_onLoadDoctorProfileRequested);
    on<LoadConnectedPatientsRequested>(_onLoadConnectedPatientsRequested);
    on<ConnectPatientRequested>(_onConnectPatientRequested);
    on<DisconnectPatientRequested>(_onDisconnectPatientRequested);
    on<AddMedicationRequested>(_onAddMedicationRequested);
    on<UpdateMedicationRequested>(_onUpdateMedicationRequested);
    on<DeleteMedicationRequested>(_onDeleteMedicationRequested);
    on<ViewPatientMedicationsRequested>(_onViewPatientMedicationsRequested);
    on<ViewPatientMedicationHistoryRequested>(
      _onViewPatientMedicationHistoryRequested,
    );
  }

  Future<void> _onLoadDoctorProfileRequested(
    LoadDoctorProfileRequested event,
    Emitter<DoctorState> emit,
  ) async {
    emit(const DoctorLoading(message: "Memuat profil dokter..."));
    final result = await doctorRepository.getDoctorProfile();
    result.fold(
      (errorMessage) {
        log("DoctorBloc: Error memuat profil dokter: $errorMessage");
        emit(DoctorError(message: errorMessage));
      },
      (doctorData) {
        log("DoctorBloc: Profil dokter berhasil dimuat.");
        emit(DoctorProfileLoaded(doctorData: doctorData));
      },
    );
  }

  Future<void> _onLoadConnectedPatientsRequested(
    LoadConnectedPatientsRequested event,
    Emitter<DoctorState> emit,
  ) async {
    // Only show loading if not already loading profile
    if (state is! DoctorLoading ||
        (state as DoctorLoading).message != "Memuat profil dokter...") {
      emit(const DoctorLoading(message: "Memuat daftar pasien terhubung..."));
    }

    final result = await doctorRepository.getConnectedPatients();
    result.fold(
      (errorMessage) {
        log("DoctorBloc: Error memuat pasien terhubung: $errorMessage");
        emit(DoctorError(message: errorMessage));
      },
      (patients) {
        log("DoctorBloc: ${patients.length} pasien terhubung berhasil dimuat.");
        emit(DoctorConnectedPatientsLoaded(patients: patients));
      },
    );
  }

  Future<void> _onConnectPatientRequested(
    ConnectPatientRequested event,
    Emitter<DoctorState> emit,
  ) async {
    emit(const DoctorLoading(message: "Menghubungkan pasien..."));
    final result = await doctorRepository.connectPatient(event.patientUniqueId);
    result.fold(
      (errorMessage) {
        log("DoctorBloc: Gagal menghubungkan pasien: $errorMessage");
        emit(DoctorError(message: errorMessage));
      },
      (successMessage) {
        log("DoctorBloc: Pasien berhasil dihubungkan: $successMessage");
        emit(DoctorPatientConnectionSuccess(message: successMessage));
        // Refresh daftar pasien setelah berhasil koneksi
        add(const LoadConnectedPatientsRequested());
      },
    );
  }

  Future<void> _onDisconnectPatientRequested(
    DisconnectPatientRequested event,
    Emitter<DoctorState> emit,
  ) async {
    emit(const DoctorLoading(message: "Memutuskan koneksi pasien..."));
    final result = await doctorRepository.disconnectPatient(
      event.patientUniqueId,
    );
    result.fold(
      (errorMessage) {
        log("DoctorBloc: Gagal memutuskan koneksi pasien: $errorMessage");
        emit(DoctorError(message: errorMessage));
      },
      (successMessage) {
        log("DoctorBloc: Koneksi pasien berhasil diputuskan: $successMessage");
        emit(DoctorPatientConnectionSuccess(message: successMessage));
        // Refresh daftar pasien setelah berhasil diskoneksi
        add(const LoadConnectedPatientsRequested());
      },
    );
  }

  Future<void> _onAddMedicationRequested(
    AddMedicationRequested event,
    Emitter<DoctorState> emit,
  ) async {
    emit(const DoctorLoading(message: "Menambahkan obat..."));
    final result = await medicationRepository.addMedication(
      event.patientUniqueId,
      event.request,
    );
    result.fold(
      (errorMessage) {
        log("DoctorBloc: Gagal menambahkan obat: $errorMessage");
        emit(DoctorError(message: errorMessage));
      },
      (responseModel) {
        log("DoctorBloc: Obat berhasil ditambahkan: ${responseModel.message}");
        emit(
          DoctorMedicationActionSuccess(
            message: responseModel.message ?? 'Obat berhasil ditambahkan.',
          ),
        );
        // Opsional: Muat ulang daftar obat pasien setelah berhasil
        // add(ViewPatientMedicationsRequested(patientUniqueId: event.patientUniqueId, patientGlobalId: /* get global ID */));
      },
    );
  }

  Future<void> _onUpdateMedicationRequested(
    UpdateMedicationRequested event,
    Emitter<DoctorState> emit,
  ) async {
    emit(const DoctorLoading(message: "Memperbarui obat..."));
    final result = await medicationRepository.updateMedication(
      event.medicationId,
      event.request,
    );
    result.fold(
      (errorMessage) {
        log("DoctorBloc: Gagal memperbarui obat: $errorMessage");
        emit(DoctorError(message: errorMessage));
      },
      (responseModel) {
        log("DoctorBloc: Obat berhasil diperbarui: ${responseModel.message}");
        emit(
          DoctorMedicationActionSuccess(
            message: responseModel.message ?? 'Obat berhasil diperbarui.',
          ),
        );
        // Opsional: Muat ulang daftar obat pasien setelah berhasil
      },
    );
  }

  Future<void> _onDeleteMedicationRequested(
    DeleteMedicationRequested event,
    Emitter<DoctorState> emit,
  ) async {
    emit(const DoctorLoading(message: "Menghapus obat..."));
    final result = await medicationRepository.deleteMedication(
      event.medicationId,
    );
    result.fold(
      (errorMessage) {
        log("DoctorBloc: Gagal menghapus obat: $errorMessage");
        emit(DoctorError(message: errorMessage));
      },
      (successMessage) {
        log("DoctorBloc: Obat berhasil dihapus: $successMessage");
        emit(DoctorMedicationActionSuccess(message: successMessage));
        // Opsional: Muat ulang daftar obat pasien setelah berhasil
      },
    );
  }

  Future<void> _onViewPatientMedicationsRequested(
    ViewPatientMedicationsRequested event,
    Emitter<DoctorState> emit,
  ) async {
    emit(const DoctorLoading(message: "Memuat obat pasien..."));
    final result = await medicationRepository.getMedicationsByPatientId(
      patientUniqueId: event.patientUniqueId,
      patientGlobalId: event.patientGlobalId,
    );
    result.fold(
      (errorMessage) {
        log("DoctorBloc: Gagal memuat obat pasien: $errorMessage");
        emit(DoctorError(message: errorMessage));
      },
      (responseModel) {
        log("DoctorBloc: Obat pasien berhasil dimuat.");
        emit(DoctorPatientMedicationsLoaded(medications: responseModel.data));
      },
    );
  }

  Future<void> _onViewPatientMedicationHistoryRequested(
    ViewPatientMedicationHistoryRequested event,
    Emitter<DoctorState> emit,
  ) async {
    emit(
      const DoctorLoading(message: "Memuat riwayat konsumsi obat pasien..."),
    );
    final result = await medicationRepository.getMedicationHistoryByPatientId(
      patientUniqueId: event.patientUniqueId,
      patientGlobalId: event.patientGlobalId,
    );
    result.fold(
      (errorMessage) {
        log(
          "DoctorBloc: Gagal memuat riwayat konsumsi obat pasien: $errorMessage",
        );
        emit(DoctorError(message: errorMessage));
      },
      (responseModel) {
        log("DoctorBloc: Riwayat konsumsi obat pasien berhasil dimuat.");
        emit(
          DoctorPatientMedicationHistoryLoaded(
            // responseModel.data sudah pasti List<MedicationHistoryData> dari MedicationRepository
            medicationHistory: responseModel.data,
          ),
        );
      },
    );
  }
}
