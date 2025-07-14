part of 'camera_bloc.dart';

sealed class CameraState extends Equatable {
  const CameraState();

  @override
  List<Object> get props => [];
}

final class CameraInitial extends CameraState {}

// State saat proses pemilihan/pengambilan gambar sedang berlangsung
final class CameraLoading extends CameraState {}

// State saat gambar berhasil dipilih/diambil
final class CameraImagePickedSuccess extends CameraState {
  final File imageFile;
  const CameraImagePickedSuccess(this.imageFile);

  @override
  List<Object> get props => [imageFile];
}

// State saat terjadi error
final class CameraError extends CameraState {
  final String message;
  const CameraError(this.message);

  @override
  List<Object> get props => [message];
}
