import 'package:bloc/bloc.dart';

import 'package:manajemen_obat/data/models/repository/patient_repository.dart';
import 'package:manajemen_obat/data/models/response/doctor_response_model.dart';
import 'dart:developer';
import 'package:manajemen_obat/data/models/response/patient_response_model.dart';
import 'package:manajemen_obat/data/models/response/patient_search_result_model.dart';
part 'patient_event.dart';
part 'patient_state.dart';

class PatientBloc extends Bloc<PatientEvent, PatientState> {
  final PatientRepository patientRepository;

  PatientBloc({required this.patientRepository})
    : super(const PatientInitial()) {
    on<PatientsRequested>(_onPatientsRequested);

    on<ConnectPatientRequested>(_onConnectPatientRequested);

    on<SearchConnectedPatientsRequested>(_onSearchConnectedPatientsRequested);

    on<GetConnectedDoctorRequested>(_onGetConnectedDoctorRequested);
  }

  Future<void> _onGetConnectedDoctorRequested(
    GetConnectedDoctorRequested event,
    Emitter<PatientState> emit,
  ) async {
    emit(const ConnectedDoctorLoading()); // Emit loading state
    log(
      "PatientBloc: Menerima GetConnectedDoctorRequested. Memulai pemuatan data dokter terhubung.",
    );

    final result = await patientRepository.getConnectedDoctor('patient_id');

    result.fold(
      (errorMessage) {
        log("PatientBloc: GetConnectedDoctor Error: $errorMessage");
        emit(ConnectedDoctorError(message: errorMessage));
      },
      (doctorData) {
        log(
          "PatientBloc: GetConnectedDoctor Success: Doctor ${doctorData.name} found. Spesialisasi: ${doctorData.specialization}",
        );
        emit(ConnectedDoctorLoaded(doctorData: doctorData));
      },
    );
  }

  Future<void> _onPatientsRequested(
    PatientsRequested event,

    Emitter<PatientState> emit,
  ) async {
    emit(const PatientLoading());

    final result = await patientRepository.getPatients();

    result.fold(
      (errorMessage) => emit(PatientError(message: errorMessage)),

      (responseModel) => emit(PatientsLoaded(patients: responseModel.data)),
    );
  }

  Future<void> _onConnectPatientRequested(
    ConnectPatientRequested event,

    Emitter<PatientState> emit,
  ) async {
    emit(const PatientLoading());

    final result = await patientRepository.connectPatient(
      event.patientUniqueId,
    );

    result.fold(
      (errorMessage) => emit(PatientError(message: errorMessage)),

      (responseModel) => emit(
        PatientConnectionSuccess(
          message: responseModel.message ?? 'Pasien berhasil dihubungkan!',

          connectedPatient: responseModel.data,
        ),
      ),
    );
  }

  Future<void> _onSearchConnectedPatientsRequested(
    SearchConnectedPatientsRequested event,

    Emitter<PatientState> emit,
  ) async {
    if (event.queryNama.isEmpty) {
      emit(const ConnectedPatientsSearchLoaded(searchResults: []));

      return;
    }

    emit(const PatientLoading());

    final result = await patientRepository.searchConnectedPatients(
      event.queryNama,
    );

    result.fold(
      (errorMessage) {
        log("PatientBloc: SearchConnectedPatients Error: $errorMessage");

        emit(ConnectedPatientsSearchError(message: errorMessage));
      },

      (searchResults) {
        log(
          "PatientBloc: SearchConnectedPatients Success: ${searchResults.length} patients found.",
        );

        emit(ConnectedPatientsSearchLoaded(searchResults: searchResults));
      },
    );
  }
}
