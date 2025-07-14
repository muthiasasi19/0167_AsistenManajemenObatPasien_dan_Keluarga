part of 'camera_bloc.dart';

sealed class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object> get props => [];
}

// Event untuk meminta gambar dari galeri
class PickImageFromGalleryRequested extends CameraEvent {
  const PickImageFromGalleryRequested();
}

// Event untuk meminta gambar dari kamera
class TakeImageFromCameraRequested extends CameraEvent {
  const TakeImageFromCameraRequested();
}

// Event ketika gambar berhasil dipilih/diambil
class ImagePickedSuccess extends CameraEvent {
  final File imageFile;
  const ImagePickedSuccess(this.imageFile);

  @override
  List<Object> get props => [imageFile];
}

// Event ketika terjadi error saat memilih/mengambil gambar
class ImagePickingFailed extends CameraEvent {
  final String message;
  const ImagePickingFailed(this.message);

  @override
  List<Object> get props => [message];
}

// Event untuk mereset state kamera (misal, setelah gambar diupload)
class CameraReset extends CameraEvent {
  const CameraReset();
}
