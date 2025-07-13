// lib/presentation/Home/pasien_homescreen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart'; // Ini sudah benar
import 'package:manajemen_obat/presentation/auth/login_screen.dart';
import 'package:manajemen_obat/presentation/Home/medication_page.dart';
import 'package:manajemen_obat/presentation/profil/pasien_profil_screen.dart';
import 'package:manajemen_obat/core/core.dart'; // Import AppColors and other core utilities
import 'package:manajemen_obat/core/components/spaces.dart'; // Import spaces if used

// Import model dan bloc Anda
import 'package:manajemen_obat/data/models/response/doctor_response_model.dart';
import 'package:manajemen_obat/data/models/response/login_response_model.dart';
import 'package:manajemen_obat/presentation/pasien/bloc/patient_bloc.dart'; // Pastikan path ini benar (p_asien bukan P_asien)

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
    // Menunda pemanggilan _loadUserDataAndFetchConnectedDoctor() hingga setelah widget di-mount
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
      return Scaffold(
        backgroundColor: AppColors.lightSheet, // Apply custom background color
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.deepPurple,
            ), // Apply custom deep purple color
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightSheet, // Apply custom background color
      appBar: AppBar(
        title: const Text(
          'Dashboard Pasien',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ), // Bolder and larger title
        ),
        backgroundColor: AppColors.deepPurple, // Apply custom deep purple color
        elevation: 0, // Remove shadow
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ), // Ensure icons are white
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
        color: AppColors.deepPurple, // Refresh indicator color
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // Increased padding
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${currentUserData!.username ?? 'Pasien'}!',
                style: const TextStyle(
                  fontSize: 28, // Larger font size
                  fontWeight: FontWeight.bold,
                  color: AppColors.black, // Black for primary text
                ),
              ),
              const SizedBox(height: 8), // Adjusted spacing
              const Text(
                'Selamat datang di aplikasi Asisten Manajemen Obat.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.grey,
                ), // Grey text
              ),
              const SizedBox(height: 30),

              BlocBuilder<PatientBloc, PatientState>(
                builder: (context, state) {
                  DoctorData? displayedDoctor;
                  String? displayMessage;

                  if (state is ConnectedDoctorLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.deepPurple,
                        ), // Deep purple loading
                      ),
                    );
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
              const SizedBox(height: 30), // Increased spacing

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
              const SizedBox(height: 16), // Spacing between cards
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
              const SizedBox(height: 16), // Spacing between cards
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
        elevation: 6.0, // Increased elevation
        shadowColor: AppColors.deepPurple.withOpacity(
          0.3,
        ), // Soft purple shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // More rounded corners
          side: const BorderSide(
            color: AppColors.light,
            width: 0.5,
          ), // Subtle light border
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Increased padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(
                      10.0,
                    ), // Padding for icon background
                    decoration: BoxDecoration(
                      color: AppColors.deepPurple.withOpacity(
                        0.15,
                      ), // Deep purple with opacity
                      shape: BoxShape.circle, // Circular background
                    ),
                    child: const Icon(
                      Icons.health_and_safety_outlined,
                      size: 32, // Larger icon
                      color: AppColors.deepPurple, // Deep purple icon
                    ),
                  ),
                  const SizedBox(width: 16), // Increased spacing
                  const Text(
                    'Terhubung dengan Dokter:',
                    style: TextStyle(
                      fontSize: 18, // Larger font
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepPurple, // Deep purple text
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Increased spacing
              Text(
                doctor.name,
                style: const TextStyle(
                  fontSize: 22, // Larger font
                  fontWeight: FontWeight.w600,
                  color: AppColors.black, // Black text
                ),
              ),
              const SizedBox(height: 8), // Adjusted spacing
              Text(
                'Spesialisasi: ${doctor.specialization}',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.grey,
                ), // Grey text
              ),
              const SizedBox(height: 4), // Adjusted spacing
              Text(
                'Telp: ${doctor.phoneNumber}',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.grey,
                ), // Grey text
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 6.0, // Increased elevation
        shadowColor: AppColors.redCustom.withOpacity(
          0.3,
        ), // Soft red shadow for warning
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // More rounded corners
          side: const BorderSide(
            color: AppColors.light,
            width: 0.5,
          ), // Subtle light border
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Increased padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(
                      10.0,
                    ), // Padding for icon background
                    decoration: BoxDecoration(
                      color: AppColors.redCustom.withOpacity(
                        0.15,
                      ), // Red with opacity for warning
                      shape: BoxShape.circle, // Circular background
                    ),
                    child: const Icon(
                      Icons.person_off_outlined,
                      size: 32, // Larger icon
                      color: AppColors.redCustom, // Red warning icon
                    ),
                  ),
                  const SizedBox(width: 16), // Increased spacing
                  const Text(
                    'Status Koneksi Dokter:',
                    style: TextStyle(
                      fontSize: 18, // Larger font
                      fontWeight: FontWeight.bold,
                      color: AppColors.redCustom, // Red warning text
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Increased spacing
              Text(
                message ??
                    'Anda belum terhubung dengan dokter manapun. Dokter Anda dapat menghubungkan Anda menggunakan ID unik Anda (ID Pasien yang tersedia di halaman Profil).',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.grey,
                ), // Grey text
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
      elevation: 6.0, // Increased elevation
      shadowColor: AppColors.deepPurple.withOpacity(0.3), // Soft purple shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0), // More rounded corners
        side: const BorderSide(
          color: AppColors.light,
          width: 0.5,
        ), // Subtle light border
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0), // Match card border radius
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Increased padding
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(
                  10.0,
                ), // Padding for icon background
                decoration: BoxDecoration(
                  color: AppColors.deepPurple.withOpacity(
                    0.15,
                  ), // Deep purple with opacity
                  shape: BoxShape.circle, // Circular background
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: AppColors.deepPurple,
                ), // Larger, deep purple icon
              ),
              const SizedBox(width: 16), // Increased spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20, // Larger font
                        fontWeight: FontWeight.bold,
                        color: AppColors.black, // Black title
                      ),
                    ),
                    const SizedBox(height: 6), // Adjusted spacing
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.grey,
                      ), // Grey subtitle
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.grey,
                size: 20,
              ), // Grey arrow icon
            ],
          ),
        ),
      ),
    );
  }
}
