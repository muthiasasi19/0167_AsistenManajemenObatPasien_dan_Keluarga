import 'dart:convert';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Untuk akses secure storage
import 'package:manajemen_obat/data/models/repository/family_repository.dart'; // Impor FamilyRepository
import 'package:manajemen_obat/data/models/request/connect_patient_family_request_model.dart';
import 'package:manajemen_obat/data/models/response/connect_patient_family_response_model.dart';
import 'package:manajemen_obat/data/models/response/login_response_model.dart'; // Impor User model dari login_response_model.dart
import 'package:manajemen_obat/data/models/response/family_response_model.dart';
part 'family_event.dart';
part 'family_state.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  final FamilyRepository familyRepository;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  FamilyBloc({required this.familyRepository}) : super(const FamilyInitial()) {
    on<LoadFamilyDataRequested>(_onLoadFamilyDataRequested);
    on<LoadConnectedPatientsRequested>(_onLoadConnectedPatientsRequested);
    on<ConnectPatientRequested>(_onConnectPatientRequested);
    // on<UpdatePatientLocationRequested>(_onUpdatePatientLocationRequested); // Untuk fitur P1
  }

  // Event handler untuk memuat data profil keluarga
  Future<void> _onLoadFamilyDataRequested(
    LoadFamilyDataRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilyLoading()); // Emit loading state

    try {
      final userDataString = await _secureStorage.read(key: 'userData');
      if (userDataString != null) {
        final Map<String, dynamic> userMap = jsonDecode(userDataString);
        final familyUserData = User.fromMap(userMap);
        emit(FamilyLoaded(familyUserData: familyUserData)); // Emit loaded state
        log(
          "FamilyBloc: Data keluarga berhasil dimuat: ${familyUserData.username}",
        );

        // Setelah data keluarga dimuat, otomatis muat daftar pasien terhubung
        add(const LoadConnectedPatientsRequested());
      } else {
        log("FamilyBloc: Data user keluarga tidak ditemukan di storage.");
        emit(
          const FamilyError(
            message: 'Data user tidak ditemukan. Mohon login ulang.',
          ),
        );
      }
    } catch (e, stackTrace) {
      log("FamilyBloc: Error memuat data keluarga: $e\n$stackTrace");
      emit(
        FamilyError(message: 'Terjadi kesalahan saat memuat data profil: $e'),
      );
    }
  }

  // Event handler untuk memuat daftar pasien yang terhubung
  Future<void> _onLoadConnectedPatientsRequested(
    LoadConnectedPatientsRequested event,
    Emitter<FamilyState> emit,
  ) async {
    // Pastikan kita tidak menggantikan FamilyLoaded jika sudah ada
    // atau jika state saat ini bukan loading untuk profil
    if (state is! FamilyLoading && state is! ConnectedPatientsLoading) {
      emit(const ConnectedPatientsLoading()); // Emit loading state
    }

    log("FamilyBloc: Memulai pemuatan daftar pasien terhubung...");

    final result = await familyRepository.getConnectedPatientsForFamily();

    result.fold(
      (errorMessage) {
        log("FamilyBloc: Error memuat pasien terhubung: $errorMessage");
        emit(ConnectedPatientsError(message: errorMessage)); // Emit error state
      },
      (patients) {
        log("FamilyBloc: Berhasil memuat ${patients.length} pasien terhubung.");
        emit(ConnectedPatientsLoaded(patients: patients)); // Emit loaded state
      },
    );
  }

  // Event handler untuk menghubungkan pasien baru
  Future<void> _onConnectPatientRequested(
    ConnectPatientRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const PatientConnecting()); // Emit state sedang menghubungkan

    log(
      "FamilyBloc: Mengirim request untuk menghubungkan pasien: ${event.patientUniqueId}",
    );

    final requestModel = FamilyConnectRequestModel(
      patientUniqueId: event.patientUniqueId,
      // HAPUS BARIS 'data: [],' INI, KARENA FAMILYCONNECTREQUESTMODEL TIDAK PUNYA PARAMETER 'DATA'
      // data: [],
    );
    final result = await familyRepository.connectPatientToFamily(requestModel);

    result.fold(
      (errorMessage) {
        log("FamilyBloc: Gagal menghubungkan pasien: $errorMessage");
        emit(
          PatientConnectionFailure(error: errorMessage),
        ); // Emit failure state
      },
      (successMessage) {
        log("FamilyBloc: Berhasil menghubungkan pasien: $successMessage");
        emit(
          PatientConnectionSuccess(message: successMessage),
        ); // Emit success state
        // Setelah berhasil, muat ulang daftar pasien terhubung
        add(const LoadConnectedPatientsRequested());
      },
    );
  }

  // Event handler untuk update lokasi pasien (fitur P1)
  // Future<void> _onUpdatePatientLocationRequested(
  //   UpdatePatientLocationRequested event,
  //   Emitter<FamilyState> emit,
  // ) async {
  //   // Ini akan diimplementasikan di sisi pasien, bukan keluarga.
  //   // Keluarga hanya melihat lokasi.
  //   // Untuk keluarga, jika perlu memuat lokasi real-time dari satu pasien, bisa jadi event terpisah.
  // }
}
