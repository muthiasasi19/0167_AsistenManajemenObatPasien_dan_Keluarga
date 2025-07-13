import 'package:bloc/bloc.dart';
import 'package:manajemen_obat/data/models/request/register_request_model.dart';
import 'package:manajemen_obat/data/models/repository/auth_repository.dart';
import 'package:flutter/foundation.dart'; // Untuk debugPrint

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository authRepository;

  RegisterBloc({required this.authRepository}) : super(RegisterInitial()) {
    on<RegisterRequested>(_onRegisterRequested);
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterLoading());

    final result = await authRepository.register(event.request);

    result.fold(
      (l) {
        debugPrint('Register Failure: $l');
        emit(RegisterFailure(error: l));
      },
      (r) {
        debugPrint('Register Success: $r');
        emit(RegisterSuccess(message: r));
      },
    );
  }

  // PASTIKAN TIDAK ADA EKSTENSI SALAH DI SINI LAGI!
}
