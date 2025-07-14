// lib/presentation/patient_location/bloc/patient_location_state.dart
part of 'patient_location_bloc.dart'; // Penting: Pastikan ini benar

// Menandakan bahwa class ini imutable
sealed class PatientLocationState {
  const PatientLocationState();
}

// State awal
class PatientLocationInitial extends PatientLocationState {}

// State saat sedang memuat lokasi
class PatientLocationLoading extends PatientLocationState {}

// State saat lokasi berhasil dimuat
class PatientLocationLoaded extends PatientLocationState {
  final PatientLocationData? locationData; // Bisa null jika tidak ada lokasi

  const PatientLocationLoaded({this.locationData});

  // Tidak perlu override props karena tidak pakai Equatable
  // @override
  // String toString() => 'PatientLocationLoaded { locationData: $locationData }';
}

// FIX ERROR: State saat pengiriman lokasi berhasil (sudah ada)
class SendLocationSuccess extends PatientLocationState {
  final String message;
  const SendLocationSuccess(this.message);
}

// FIX ERROR: State saat terjadi error dalam pengiriman lokasi (sudah ada)
class SendLocationError extends PatientLocationState {
  final String message;
  const SendLocationError(this.message);
}

// State saat terjadi error dalam memuat lokasi
class PatientLocationError extends PatientLocationState {
  final String message;

  const PatientLocationError(this.message);

  // Tidak perlu override props karena tidak pakai Equatable
  // @override
  // String toString() => 'PatientLocationError { message: $message }';
}
// TIL HERE