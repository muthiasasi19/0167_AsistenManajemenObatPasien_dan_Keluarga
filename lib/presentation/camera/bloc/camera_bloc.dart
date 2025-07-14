import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart'; // Import ImagePicker
import 'dart:developer' as developer;

part 'camera_event.dart';
part 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final ImagePicker _picker = ImagePicker(); // Instansiasi ImagePicker

  CameraBloc() : super(CameraInitial()) {
    on<PickImageFromGalleryRequested>(_onPickImageFromGalleryRequested);
    on<TakeImageFromCameraRequested>(_onTakeImageFromCameraRequested);
    on<CameraReset>(_onCameraReset);
  }

  Future<void> _onPickImageFromGalleryRequested(
    PickImageFromGalleryRequested event,
    Emitter<CameraState> emit,
  ) async {
    emit(CameraLoading());
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        developer.log(
          'CameraBloc: Image picked from gallery: ${imageFile.path}',
        );
        emit(CameraImagePickedSuccess(imageFile));
      } else {
        developer.log('CameraBloc: Image picking cancelled by user (gallery).');
        emit(CameraError('Pemilihan gambar dibatalkan.'));
      }
    } catch (e, st) {
      developer.log('CameraBloc: Error picking image from gallery: $e\n$st');
      emit(CameraError('Gagal memilih gambar dari galeri: $e'));
    }
  }

  Future<void> _onTakeImageFromCameraRequested(
    TakeImageFromCameraRequested event,
    Emitter<CameraState> emit,
  ) async {
    emit(CameraLoading());
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
      );
      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        developer.log('CameraBloc: Image taken from camera: ${imageFile.path}');
        emit(CameraImagePickedSuccess(imageFile));
      } else {
        developer.log('CameraBloc: Image taking cancelled by user (camera).');
        emit(CameraError('Pengambilan gambar dibatalkan.'));
      }
    } catch (e, st) {
      developer.log('CameraBloc: Error taking image from camera: $e\n$st');
      emit(CameraError('Gagal mengambil gambar dari kamera: $e'));
    }
  }

  void _onCameraReset(CameraReset event, Emitter<CameraState> emit) {
    emit(CameraInitial());
  }
}
