import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manajemen_obat/presentation/auth/login_screen.dart';
import 'package:manajemen_obat/presentation/Home/medication_page.dart';
import 'package:manajemen_obat/presentation/profil/pasien_profil_screen.dart';
import 'package:manajemen_obat/data/models/response/doctor_response_model.dart';
import 'package:manajemen_obat/data/models/response/login_response_model.dart';
import 'package:manajemen_obat/presentation/pasien/bloc/patient_bloc.dart';

class PasienHomeScreen extends StatefulWidget {
  const PasienHomeScreen({super.key});

  @override
  State<PasienHomeScreen> createState() => _PasienHomeScreenState();
}

class _PasienHomeScreenState extends State<PasienHomeScreen> {
  User? currentUserData;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserDataAndFetchConnectedDoctor();
    });
  }

  Future<void> _loadUserDataAndFetchConnectedDoctor() async {
    try {
      final userDataString = await _secureStorage.read(key: 'userData');
      if (userDataString != null) {
        final Map<String, dynamic> userMap = jsonDecode(userDataString);
        setState(() {
          currentUserData = User.fromMap(userMap);
        });

        if (currentUserData != null && currentUserData!.idPasien != null) {
          context.read<PatientBloc>().add(const GetConnectedDoctorRequested());
        } else {
          print(
            "PasienHomeScreen: Data ID pasien tidak ditemukan setelah login.",
          );
        }
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('PasienHomeScreen: Error saat memuat data user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pasien'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _secureStorage.delete(key: 'authToken');
              await _secureStorage.delete(key: 'userRole');
              await _secureStorage.delete(key: 'userData');
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
      body: RefreshIndicator(
        onRefresh: _loadUserDataAndFetchConnectedDoctor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${currentUserData!.username ?? 'Pasien'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Selamat datang di aplikasi Asisten Manajemen Obat.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              BlocBuilder<PatientBloc, PatientState>(
                builder: (context, state) {
                  DoctorData? displayedDoctor;
                  String? displayMessage;

                  if (state is ConnectedDoctorLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ConnectedDoctorLoaded) {
                    displayedDoctor = state.doctorData;
                  } else if (state is ConnectedDoctorError) {
                    displayMessage = state.message;
                  } else {
                    displayMessage = 'Memuat status koneksi dokter...';
                  }

                  return _buildConnectedDoctorSection(
                    context,
                    displayedDoctor,
                    displayMessage,
                  );
                },
              ),
              const SizedBox(height: 20),

              _buildFeatureCard(
                context,
                icon: Icons.access_time_outlined,
                title: 'Jadwal Konsumsi Obat',
                subtitle:
                    'Lihat jadwal obat Anda dan tandai yang sudah diminum.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const MedicationPage(isPatientRole: true),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.history_edu_outlined,
                title: 'Riwayat Konsumsi Obat',
                subtitle: 'Periksa riwayat obat yang sudah Anda minum.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => const MedicationPage(
                            isHistory: true,
                            isPatientRole: true,
                          ),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                icon: Icons.person_outline,
                title: 'Profil Saya',
                subtitle: 'Lihat dan perbarui informasi profil pribadi Anda.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PasienProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedDoctorSection(
    BuildContext context,
    DoctorData? doctor,
    String? message,
  ) {
    if (doctor != null) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 3.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    size: 30,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Terhubung dengan Dokter:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                doctor.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Spesialisasi: ${doctor.specialization}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              Text(
                'Telp: ${doctor.phoneNumber}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 3.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 30,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Status Koneksi Dokter:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                message ??
                    'Anda belum terhubung dengan dokter manapun. Dokter Anda dapat menghubungkan Anda menggunakan ID unik Anda (ID Pasien yang tersedia di halaman Profil).',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
  }

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
}
