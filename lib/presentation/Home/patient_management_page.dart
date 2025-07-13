// lib/presentation/home/patient_management_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manajemen_obat/core/core.dart';
import 'package:manajemen_obat/data/models/response/patient_response_model.dart';
import 'package:manajemen_obat/data/models/response/patient_search_result_model.dart';
import 'package:manajemen_obat/presentation/pasien/bloc/patient_bloc.dart';
import 'package:manajemen_obat/presentation/Home/medication_page.dart';

class PatientManagementPage extends StatefulWidget {
  const PatientManagementPage({super.key});

  @override
  State<PatientManagementPage> createState() => _PatientManagementPageState();
}

class _PatientManagementPageState extends State<PatientManagementPage> {
  final TextEditingController _connectPatientIdController =
      TextEditingController();
  final GlobalKey<FormState> _connectPatientFormKey = GlobalKey<FormState>();

  final TextEditingController _searchController = TextEditingController();
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<PatientBloc>().add(PatientsRequested());

    _searchController.addListener(() {
      if (_searchController.text.trim() != _currentSearchQuery) {
        setState(() {
          _currentSearchQuery = _searchController.text.trim();
        });
        if (_currentSearchQuery.isNotEmpty && _currentSearchQuery.length >= 2) {
          context.read<PatientBloc>().add(
            SearchConnectedPatientsRequested(queryNama: _currentSearchQuery),
          );
        } else if (_currentSearchQuery.isEmpty) {
          context.read<PatientBloc>().add(PatientsRequested());
        }
      }
    });
  }

  @override
  void dispose() {
    _connectPatientIdController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(
    String labelText, {
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _showConnectPatientDialog(BuildContext dialogContext) async {
    _connectPatientIdController.clear();

    await showDialog(
      context: dialogContext,
      builder: (context) {
        return BlocListener<PatientBloc, PatientState>(
          listener: (listenerContext, state) {
            if (state is PatientConnectionSuccess) {
              ScaffoldMessenger.of(
                listenerContext,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              Navigator.pop(listenerContext);
              listenerContext.read<PatientBloc>().add(PatientsRequested());
            } else if (state is PatientError) {
              ScaffoldMessenger.of(listenerContext).showSnackBar(
                SnackBar(content: Text('Error: ${state.message}')),
              );
            }
          },
          child: AlertDialog(
            title: const Text('Hubungkan Pasien Baru'),
            content: Form(
              key: _connectPatientFormKey,
              child: TextFormField(
                controller: _connectPatientIdController,
                decoration: _inputDecoration('ID Unik Pasien'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ID Pasien wajib diisi';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_connectPatientFormKey.currentState!.validate()) {
                    context.read<PatientBloc>().add(
                      ConnectPatientRequested(
                        patientUniqueId:
                            _connectPatientIdController.text.trim(),
                      ),
                    );
                  }
                },
                child: BlocBuilder<PatientBloc, PatientState>(
                  builder: (context, state) {
                    return Text(
                      state is PatientLoading &&
                              _connectPatientFormKey.currentContext != null
                          ? 'Menghubungkan...'
                          : 'Hubungkan',
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pasien & Obat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: _searchController,
              decoration: _inputDecoration(
                'Cari Nama Pasien Terhubung',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<PatientBloc>().add(
                              PatientsRequested(),
                            );
                          },
                        )
                        : null,
              ),
            ),
          ),
          Expanded(
            child: BlocConsumer<PatientBloc, PatientState>(
              listener: (context, state) {
                if (state is PatientLoading &&
                    _connectPatientFormKey.currentContext == null) {
                  // No snackbar on loading, rely on CircularProgressIndicator
                } else if (state is PatientError &&
                    _connectPatientFormKey.currentContext == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${state.message}')),
                  );
                }
              },
              builder: (context, state) {
                if (state is PatientInitial || state is PatientLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is PatientsLoaded) {
                  if (state.patients.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada pasien yang terhubung dengan dokter ini. Klik (+) untuk menambahkan.',
                      ),
                    );
                  }
                  return _buildPatientList(state.patients);
                } else if (state is ConnectedPatientsSearchLoaded) {
                  if (state.searchResults.isEmpty) {
                    return Center(
                      child: Text(
                        'Tidak ada pasien terhubung ditemukan dengan nama "${_currentSearchQuery}".',
                      ),
                    );
                  }
                  return _buildPatientListFromSearchResults(
                    state.searchResults,
                  );
                } else if (state is PatientError) {
                  return Center(
                    child: Text('Gagal memuat daftar pasien: ${state.message}'),
                  );
                }
                return const Center(
                  child: Text('Tidak ada pasien untuk ditampilkan.'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showConnectPatientDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // INI YANG AKU PERBAIKI: Fungsi _buildPatientList dipindahkan ke dalam kelas _PatientManagementPageState
  Widget _buildPatientList(List<Patient> patients) {
    return ListView.builder(
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ), // Memberikan border radius pada Card
          child: ExpansionTile(
            // Mengubah ListTile menjadi ExpansionTile
            leading: const Icon(Icons.person),
            title: Text(patient.name),
            subtitle: Text('ID: ${patient.patientId}'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Tombol "Obat"
                    _buildSmallFeatureButton(
                      context,
                      icon: Icons.medication_outlined,
                      label: 'Obat',
                      onTap: () {
                        context.push(
                          MedicationPage(
                            initialPatientUniqueId:
                                patient.patientId, // Kirim ID Unik pasien
                            initialPatientName:
                                patient.name, // Kirim nama pasien
                            isHistory:
                                false, // Bukan riwayat, ini manajemen/jadwal
                            isPatientRole: false, // Dokter bukan pasien
                            isFamilyRole: false, // Dokter bukan keluarga
                          ),
                        );
                      },
                    ),
                    // Tombol "Riwayat"
                    _buildSmallFeatureButton(
                      context,
                      icon: Icons.history_edu_outlined,
                      label: 'Riwayat',
                      onTap: () {
                        context.push(
                          MedicationPage(
                            initialPatientUniqueId:
                                patient.patientId, // Kirim ID Unik pasien
                            initialPatientName:
                                patient.name, // Kirim nama pasien
                            isHistory: true, // Ini adalah riwayat
                            isPatientRole: false, // Dokter bukan pasien
                            isFamilyRole: false, // Dokter bukan keluarga
                          ),
                        );
                      },
                    ),
                    // Tidak ada tombol "Lokasi" untuk dokter
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // INI YANG AKU PERBAIKI: Fungsi _buildPatientListFromSearchResults dipindahkan ke dalam kelas _PatientManagementPageState
  Widget _buildPatientListFromSearchResults(
    List<PatientSearchResult> searchResults,
  ) {
    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final patient = searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: ExpansionTile(
            // Mengubah ListTile menjadi ExpansionTile
            leading: const Icon(Icons.person),
            title: Text(patient.nama),
            subtitle: Text('ID: ${patient.idUnik}'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Tombol "Obat"
                    _buildSmallFeatureButton(
                      context,
                      icon: Icons.medication_outlined,
                      label: 'Obat',
                      onTap: () {
                        context.push(
                          MedicationPage(
                            initialPatientUniqueId:
                                patient.idUnik, // Kirim ID Unik pasien
                            initialPatientName:
                                patient.nama, // Kirim nama pasien
                            isHistory: false,
                            isPatientRole: false,
                            isFamilyRole: false,
                          ),
                        );
                      },
                    ),
                    // Tombol "Riwayat"
                    _buildSmallFeatureButton(
                      context,
                      icon: Icons.history_edu_outlined,
                      label: 'Riwayat',
                      onTap: () {
                        context.push(
                          MedicationPage(
                            initialPatientUniqueId:
                                patient.idUnik, // Kirim ID Unik pasien
                            initialPatientName:
                                patient.nama, // Kirim nama pasien
                            isHistory: true,
                            isPatientRole: false,
                            isFamilyRole: false,
                          ),
                        );
                      },
                    ),
                    // Tidak ada tombol "Lokasi" untuk dokter
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmallFeatureButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      // Menggunakan Card untuk setiap tombol kecil agar ada elevasi dan shape
      margin: EdgeInsets.zero, // Menghilangkan margin antar card
      elevation: 0, // Mengurangi elevasi agar tidak terlalu menonjol
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ), // Memberikan border radius
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ), // Padding di dalam tombol
          child: Column(
            mainAxisSize: MainAxisSize.min, // Memastikan Column tidak melebar
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context).primaryColor,
              ), // Ukuran ikon disesuaikan
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// class RiwayatKonsumsiPasien extends StatelessWidget {
//   // --- PERBAIKAN: Ubah tipe data patientGlobalId menjadi String ---
//   final String patientGlobalId;
//   // --- AKHIR PERBAIKAN ---

//   const RiwayatKonsumsiPasien({super.key, required this.patientGlobalId});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Riwayat Konsumsi Obat')),
//       body: Center(
//         child: Text(
//           'Halaman Riwayat Konsumsi untuk Pasien ID: $patientGlobalId\nImplementasi UI/Logika akan ada di sini.',
//         ),
//       ),
//     );
//   }
// }
