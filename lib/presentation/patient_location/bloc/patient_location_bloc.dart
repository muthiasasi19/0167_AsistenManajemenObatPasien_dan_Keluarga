import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:manajemen_obat/data/models/repository/family_repository.dart';
import 'package:manajemen_obat/data/models/repository/patient_repository.dart';
import 'package:manajemen_obat/data/models/response/patient_location_response_model.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

part 'patient_location_event.dart';
part 'patient_location_state.dart';

class PatientLocationBloc
    extends Bloc<PatientLocationEvent, PatientLocationState> {
  final FamilyRepository familyRepository;
  final PatientRepository patientRepository;
  Timer? _pollingTimer;

  PatientLocationBloc({
    required this.familyRepository,
    required this.patientRepository,
  }) : super(PatientLocationInitial()) {
    on<LoadPatientLocationRequested>(_onLoadPatientLocationRequested);
    // FIX ERROR: Tambahkan handler untuk event pengiriman lokasi
    on<SendPatientLocationRequested>(_onSendPatientLocationRequested);
  }

  Future<void> _onLoadPatientLocationRequested(
    LoadPatientLocationRequested event,
    Emitter<PatientLocationState> emit,
  ) async {
    if (!emit.isDone) {
      emit(PatientLocationLoading());
    }

    _pollingTimer?.cancel();

    try {
      final result = await familyRepository.getPatientLastLocationForFamily(
        event.patientGlobalId,
      );

      result.fold(
        (error) {
          developer.log('FITUR MAPS BLoC: Gagal memuat lokasi awal: $error');
          if (!emit.isDone) {
            emit(PatientLocationError(error));
          }
        },
        (locationData) {
          developer.log(
            'FITUR MAPS BLoC: Lokasi awal dimuat: ${locationData.toMap()}',
          );
          if (!emit.isDone) {
            emit(PatientLocationLoaded(locationData: locationData));
          }
        },
      );
    } catch (e, stackTrace) {
      developer.log(
        'FITUR MAPS BLoC: Error memuat lokasi awal: $e\n$stackTrace',
      );
      if (!emit.isDone) {
        emit(
          PatientLocationError('Terjadi kesalahan saat memuat lokasi awal: $e'),
        );
      }
    }

    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      try {
        final result = await familyRepository.getPatientLastLocationForFamily(
          event.patientGlobalId,
        );

        result.fold(
          (error) {
            developer.log(
              'FITUR MAPS BLoC: Gagal memuat lokasi berkala: $error',
            );
            if (!emit.isDone) {
              emit(PatientLocationError(error));
            }
          },
          (locationData) {
            developer.log(
              'FITUR MAPS BLoC: Lokasi berkala dimuat: ${locationData.toMap()}',
            );
            if (!emit.isDone) {
              emit(PatientLocationLoaded(locationData: locationData));
            }
          },
        );
      } catch (e, stackTrace) {
        developer.log(
          'FITUR MAPS BLoC: Error polling lokasi berkala: $e\n$stackTrace',
        );
        if (!emit.isDone) {
          emit(
            PatientLocationError('Terjadi kesalahan saat polling lokasi: $e'),
          );
        }
      }
    });
  }

  // FIX ERROR: Tambahkan method handler untuk SendPatientLocationRequested
  Future<void> _onSendPatientLocationRequested(
    SendPatientLocationRequested event,
    Emitter<PatientLocationState> emit,
  ) async {
    // Anda bisa emit loading state di sini jika diperlukan feedback UI segera
    // emit(PatientLocationLoading()); // Opsional

    final result = await patientRepository.sendPatientLocation(
      event.latitude,
      event.longitude,
    );

    result.fold(
      (error) {
        developer.log('PatientLocationBloc: Gagal mengirim lokasi: $error');
        emit(SendLocationError(error)); // Emit state Error
      },
      (data) {
        developer.log(
          'PatientLocationBloc: Lokasi berhasil dikirim: ${data.toMap()}',
        );
        emit(
          const SendLocationSuccess('Lokasi berhasil dikirim!'),
        ); // Emit state Sukses
      },
    );
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    developer.log(
      'FITUR MAPS BLoC: PatientLocationBloc ditutup, timer dibatalkan.',
    );
    return super.close();
  }
}
