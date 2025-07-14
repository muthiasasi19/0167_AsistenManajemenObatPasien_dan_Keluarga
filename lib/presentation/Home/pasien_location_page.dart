// lib/presentation/Home/pasien_location_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manajemen_obat/core/core.dart'; // Untuk AppColors
import 'package:manajemen_obat/data/models/response/patient_location_response_model.dart';

import 'package:manajemen_obat/presentation/patient_location/bloc/patient_location_bloc.dart';

class PasienLocationPage extends StatefulWidget {
  final int patientGlobalId;

  const PasienLocationPage({super.key, required this.patientGlobalId});

  @override
  State<PasienLocationPage> createState() => _PasienLocationPageState();
}

class _PasienLocationPageState extends State<PasienLocationPage> {
  // FITUR MAPS: Menggunakan Completer untuk GoogleMapController
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;

  Set<Marker> _markers = {}; // Set untuk menyimpan marker
  LatLng? _currentPatientLatLng; // Lokasi pasien saat ini

  // Posisi kamera default (Yogyakarta sebagai contoh)
  static const CameraPosition _kDefaultInitialCameraPosition = CameraPosition(
    target: LatLng(-7.7956, 110.3695), // Koordinat Yogyakarta
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    // FITUR MAPS: Panggil event untuk memuat lokasi pasien saat halaman diinisialisasi
    context.read<PatientLocationBloc>().add(
      LoadPatientLocationRequested(patientGlobalId: widget.patientGlobalId),
    );
  }

  // FITUR MAPS: Callback saat Google Map dibuat
  void _onMapCreated(GoogleMapController controller) {
    _mapControllerCompleter.complete(controller);
    _mapController = controller;
    // Jika lokasi pasien sudah ada saat map dibuat, animasikan kamera ke sana
    if (_currentPatientLatLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPatientLatLng!, 16.0),
      );
    }
  }

  // FITUR MAPS: Memperbarui marker dan posisi kamera saat ada data lokasi baru
  void _updateMapWithLocation(PatientLocationData locationData) {
    if (locationData.latitude != null && locationData.longitude != null) {
      final newLatLng = LatLng(locationData.latitude!, locationData.longitude!);
      setState(() {
        _currentPatientLatLng = newLatLng;
        _markers.clear(); // Hapus marker lama
        _markers.add(
          Marker(
            markerId: const MarkerId('patient_location'),
            position: newLatLng,
            infoWindow: InfoWindow(
              title: 'Lokasi Pasien',
              snippet:
                  'Terakhir diperbarui: ${locationData.timestamp ?? "N/A"}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ), // Marker biru
          ),
        );
      });

      // Animasikan kamera ke lokasi baru jika controller sudah siap
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newLatLng, 16.0), // Zoom lebih dekat
      );
    }
  }

  @override
  void dispose() {
    // Pastikan tidak ada resource yang bocor, meskipun BLoC yang mengelola timer
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lokasi Pasien',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      // FITUR MAPS: Menggunakan BlocConsumer untuk mendengarkan state lokasi pasien
      body: BlocConsumer<PatientLocationBloc, PatientLocationState>(
        listener: (context, state) {
          if (state is PatientLocationLoaded && state.locationData != null) {
            _updateMapWithLocation(state.locationData!);
          } else if (state is PatientLocationError) {
            // Tampilkan SnackBar atau dialog untuk error
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is PatientLocationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PatientLocationLoaded) {
            // Tampilkan peta jika ada data lokasi yang valid
            if (state.locationData != null &&
                state.locationData!.latitude != null &&
                state.locationData!.longitude != null) {
              return GoogleMap(
                mapType: MapType.normal,
                // Gunakan lokasi pasien terakhir jika tersedia, jika tidak, gunakan default
                initialCameraPosition:
                    _currentPatientLatLng != null
                        ? CameraPosition(
                          target: _currentPatientLatLng!,
                          zoom: 16.0, // Zoom yang lebih dekat
                        )
                        : _kDefaultInitialCameraPosition,
                onMapCreated: _onMapCreated,
                markers: _markers,
                myLocationButtonEnabled: true, // Tombol lokasi saya di peta
                myLocationEnabled:
                    true, // Tampilkan titik lokasi saya (keluarga)
                zoomControlsEnabled: true, // Kontrol zoom
                compassEnabled: true,
                tiltGesturesEnabled: false,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                trafficEnabled: false, // Tidak menampilkan traffic
                buildingsEnabled: true,
                indoorViewEnabled: false, // Tidak menampilkan indoor view
                onTap: (latlng) {
                  // Jika ingin keluarga bisa tap peta untuk info, bisa diimplementasikan di sini
                  // Tapi fokus utamanya adalah menampilkan lokasi pasien
                },
              );
            } else {
              // Tampilkan pesan jika lokasi pasien tidak tersedia
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 80, color: AppColors.grey),
                      SizedBox(height: 20),
                      Text(
                        'Lokasi pasien belum tersedia atau tidak dapat dimuat.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Pastikan pasien mengaktifkan izin lokasi di perangkatnya dan aplikasi pasien berjalan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }
          } else if (state is PatientLocationError) {
            // Tampilkan pesan error
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: AppColors.redCustom,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Error: ${state.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.redCustom,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Gagal memuat peta lokasi. Cek koneksi internet Anda atau coba lagi nanti.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink(); // Fallback untuk state tak terduga
        },
      ),
      // Tombol FAB tidak diperlukan di sini karena ini hanya tampilan lokasi, bukan pemilihan.
      // FloatingActionButton: Column(...),
    );
  }
}
