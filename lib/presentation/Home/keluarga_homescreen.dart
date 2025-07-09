import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:developer';
import 'package:manajemen_obat/core/core.dart';
import 'package:manajemen_obat/data/models/response/connect_patient_family_response_model.dart';
import 'package:manajemen_obat/presentation/auth/login_screen.dart';
import 'package:manajemen_obat/presentation/profil/keluarga_profil_screen.dart';
import 'package:manajemen_obat/data/models/response/login_response_model.dart';
import 'package:manajemen_obat/presentation/family/bloc/family_bloc.dart';
import 'package:manajemen_obat/presentation/Home/medication_page.dart';
import 'package:manajemen_obat/presentation/Home/pasien_location_page.dart';

class KeluargaHomeScreen extends StatefulWidget {
  const KeluargaHomeScreen({super.key});

  @override
  State<KeluargaHomeScreen> createState() => _KeluargaHomeScreenState();
}

class _KeluargaHomeScreenState extends State<KeluargaHomeScreen> {
  User? _familyUserData;
  List<FamilyConnectedPatientData> _connectedPatients = [];
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Controller untuk dialog koneksi pasien
  final TextEditingController _connectPatientIdController =
      TextEditingController();
  final GlobalKey<FormState> _connectPatientFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Memuat data profil keluarga dan daftar pasien terhubung saat inisialisasi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyBloc>().add(const LoadFamilyDataRequested());
    });
  }

  @override
  void dispose() {
    _connectPatientIdController.dispose();
    _connectPatientFormKey.currentState?.dispose();
    super.dispose();
  }

  // Helper method untuk styling InputDecoration
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

  //  untuk menghubungkan pasien baru
  Future<void> _showConnectPatientDialog(BuildContext dialogContext) async {
    _connectPatientIdController
        .clear(); // untuk bersihkan input setiap kali dialog dibuka

    await showDialog(
      context: dialogContext,
      builder: (context) {
        return BlocListener<FamilyBloc, FamilyState>(
          listener: (listenerContext, state) {
            if (state is PatientConnectionSuccess) {
              ScaffoldMessenger.of(
                listenerContext,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              Navigator.pop(listenerContext);
            } else if (state is PatientConnectionFailure) {
              ScaffoldMessenger.of(
                listenerContext,
              ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
            }
          },
          child: AlertDialog(
            title: const Text('Hubungkan Pasien Baru'),
            content: Form(
              key: _connectPatientFormKey,
              child: TextFormField(
                controller: _connectPatientIdController,
                decoration: _inputDecoration('ID Unik Pasien (contoh: PSN...)'),
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
              BlocBuilder<FamilyBloc, FamilyState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed:
                        state is PatientConnecting
                            ? null
                            : () {
                              if (_connectPatientFormKey.currentState!
                                  .validate()) {
                                context.read<FamilyBloc>().add(
                                  ConnectPatientRequested(
                                    patientUniqueId:
                                        _connectPatientIdController.text.trim(),
                                    familyId: _familyUserData?.idKeluarga,
                                    familyGlobalId:
                                        _familyUserData?.familyGlobalId,
                                  ),
                                );
                              }
                            },
                    child: Text(
                      state is PatientConnecting
                          ? 'Menghubungkan...'
                          : 'Hubungkan',
                    ),
                  );
                },
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
      appBar: AppBar(
        title: const Text('Dashboard Keluarga'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _secureStorage.deleteAll();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),

      body: BlocConsumer<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (state is FamilyLoaded) {
            setState(() {
              _familyUserData = state.familyUserData;
            });
            log(
              'KeluargaHomeScreen: FamilyLoaded state received. _familyUserData updated.',
            );
          } else if (state is ConnectedPatientsLoaded) {
            setState(() {
              _connectedPatients = state.patients;
            });
            log(
              'KeluargaHomeScreen: ConnectedPatientsLoaded state received. _connectedPatients updated. Count: ${_connectedPatients.length}',
            );
          } else if (state is FamilyError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
            log('KeluargaHomeScreen: FamilyError: ${state.message}');
            setState(() {
              _familyUserData = null;
            });
          } else if (state is ConnectedPatientsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error memuat pasien: ${state.message}')),
            );
            log('KeluargaHomeScreen: ConnectedPatientsError: ${state.message}');
            setState(() {
              _connectedPatients = [];
            });
          } else if (state is PatientConnectionSuccess) {
            log(
              'KeluargaHomeScreen: PatientConnectionSuccess received. Dialog should close.',
            );
          } else if (state is PatientConnectionFailure) {
            log(
              'KeluargaHomeScreen: PatientConnectionFailure received. Error: ${state.error}',
            );
          }
        },
        builder: (context, state) {
          if (state is FamilyLoading ||
              (state is ConnectedPatientsLoading && _familyUserData == null)) {
            log(
              'KeluargaHomeScreen: Displaying full screen loading. Current State: ${state.runtimeType}',
            ); //Log state loading
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            );
          }

          if (_familyUserData == null) {
            log(
              'KeluargaHomeScreen: _familyUserData is null, showing initial data load error.',
            );
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data profil keluarga. Mohon pastikan Anda sudah login dengan akun keluarga yang valid.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<FamilyBloc>().add(
                          const LoadFamilyDataRequested(),
                        );
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<FamilyBloc>().add(const LoadFamilyDataRequested());
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${_familyUserData!.namaKeluarga ?? _familyUserData!.username ?? 'Anggota Keluarga'}!', // INILOH: Menggunakan _familyUserData
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_familyUserData!.idKeluarga != null)
                    Text(
                      'ID Keluarga Anda: ${_familyUserData!.idKeluarga}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                      ),
                    ),
                  const Text(
                    'Pantau kesehatan anggota keluarga Anda di sini.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  _buildFeatureCard(
                    context,
                    icon: Icons.person_add_alt_1_outlined,
                    title: 'Hubungkan Pasien Baru',
                    subtitle:
                        'Tambahkan pasien yang ingin Anda pantau dengan kode unik pasien (PSN...).',
                    onTap: () => _showConnectPatientDialog(context),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Pasien yang Terhubung:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),

                  BlocBuilder<FamilyBloc, FamilyState>(
                    buildWhen:
                        (previous, current) =>
                            current is ConnectedPatientsLoaded ||
                            current is ConnectedPatientsError ||
                            current is ConnectedPatientsLoading,
                    builder: (context, state) {
                      if (state is ConnectedPatientsLoading &&
                          _familyUserData != null) {
                        log(
                          'KeluargaHomeScreen: Displaying connected patients loading. State: ${state.runtimeType}',
                        ); //  Log loading pasien
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.deepPurple,
                            ),
                          ),
                        );
                      }
                      //  Untuk menampilkan daftar pasien dari _connectedPatients
                      else if (state is ConnectedPatientsLoaded ||
                          _connectedPatients.isNotEmpty) {
                        if (_connectedPatients.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Belum ada pasien yang terhubung. Hubungkan pasien baru di atas.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _connectedPatients.length,
                          itemBuilder: (context, index) {
                            final patient = _connectedPatients[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 2.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: ExpansionTile(
                                leading: const Icon(Icons.person),
                                title: Text(patient.nama ?? 'Nama Pasien'),
                                subtitle: Text(
                                  'ID Unik: ${patient.idUnik ?? 'N/A'}',
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tanggal Lahir: ${patient.tanggalLahir != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(patient.tanggalLahir!)) : 'N/A'}',
                                        ),
                                        Text(
                                          'Jenis Kelamin: ${patient.jenisKelamin ?? 'N/A'}',
                                        ),
                                        Text(
                                          'No. Telepon: ${patient.nomorTelepon ?? 'N/A'}',
                                        ),
                                        Text(
                                          'Alamat: ${patient.alamat ?? 'N/A'}',
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildSmallFeatureButton(
                                              context,
                                              icon: Icons.access_time_outlined,
                                              label: 'Obat',
                                              onTap: () {
                                                if (patient.idGlobal != null &&
                                                    patient.idUnik != null) {
                                                  context.push(
                                                    MedicationPage(
                                                      patientGlobalId:
                                                          patient.idGlobal!,
                                                      initialPatientUniqueId:
                                                          patient.idUnik!,
                                                      isFamilyRole: true,
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'ID Global Pasien tidak tersedia.',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                            _buildSmallFeatureButton(
                                              context,
                                              icon: Icons.history_edu_outlined,
                                              label: 'Riwayat',
                                              onTap: () {
                                                if (patient.idGlobal != null &&
                                                    patient.idUnik != null) {
                                                  context.push(
                                                    MedicationPage(
                                                      patientGlobalId:
                                                          patient.idGlobal!,
                                                      initialPatientUniqueId:
                                                          patient.idUnik!,
                                                      isHistory: true,
                                                      isFamilyRole: true,
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'ID Pasien tidak tersedia untuk fitur ini.',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                            _buildSmallFeatureButton(
                                              context,
                                              icon: Icons.location_on_outlined,
                                              label: 'Lokasi',
                                              onTap: () {
                                                if (patient.idGlobal != null) {
                                                  context.push(
                                                    PasienLocationPage(
                                                      patientGlobalId:
                                                          patient.idGlobal!,
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'ID Global Pasien tidak tersedia.',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      } else if (state is ConnectedPatientsError) {
                        log(
                          'KeluargaHomeScreen: ConnectedPatientsError, showing error message. Message: ${state.message}',
                        ); // Log error
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.warning_amber,
                                  color: Colors.orange,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Gagal memuat pasien: ${state.message}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<FamilyBloc>().add(
                                      const LoadConnectedPatientsRequested(),
                                    );
                                  },
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      // Default fallback jika tidak ada state yang cocok
                      log(
                        'KeluargaHomeScreen: ConnectedPatients BlocBuilder fallback. Current State: ${state.runtimeType}',
                      ); // I Log fallback
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 30),
                  _buildFeatureCard(
                    context,
                    icon: Icons.person_outline,
                    title: 'Profil Saya',
                    subtitle:
                        'Lihat dan perbarui informasi profil pribadi Anda.',
                    onTap: () {
                      context.push(const KeluargaProfileScreen());
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget  card
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget small card button
  Widget _buildSmallFeatureButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
