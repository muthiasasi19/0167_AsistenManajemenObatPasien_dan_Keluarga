import 'package:flutter/material.dart';

class PasienLocationPage extends StatefulWidget {
  final int patientGlobalId;

  const PasienLocationPage({super.key, required this.patientGlobalId});

  @override
  State<PasienLocationPage> createState() => _PasienLocationPageState();
}

class _PasienLocationPageState extends State<PasienLocationPage> {
  @override
  void initState() {
    super.initState();
    // Anda akan memuat data lokasi di sini menggunakan BLoC atau langsung dari repository
    // Contoh: context.read<FamilyBloc>().add(LoadPatientLocationRequested(patientGlobalId: widget.patientGlobalId));
    // Atau: _loadLocationData();
  }

  @override
  Widget build(BuildContext context) {
    // Untuk saat ini, hanya menampilkan placeholder
    return Scaffold(
      appBar: AppBar(title: const Text('Lokasi Pasien')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_outlined, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 20),
              Text(
                'Halaman Lokasi Pasien ID Global: ${widget.patientGlobalId}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Area ini akan menampilkan peta lokasi real-time pasien menggunakan Google Maps.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              // Tombol untuk refresh atau muat ulang (opsional)
              // ElevatedButton(
              //   onPressed: _loadLocationData,
              //   child: const Text('Muat Ulang Lokasi'),
              // ),
              // isLoading
              //     ? const CircularProgressIndicator()
              //     : errorMessage != null
              //         ? Text('Error: $errorMessage')
              //         : currentLocation != null
              //             ? Text('Lat: ${currentLocation!.latitude}, Long: ${currentLocation!.longitude}')
              //             : const Text('Lokasi belum tersedia.')
            ],
          ),
        ),
      ),
    );
  }
}
