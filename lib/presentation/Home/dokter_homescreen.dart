import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:manajemen_obat/core/core.dart';
import 'package:manajemen_obat/presentation/Home/patient_management_page.dart';
import 'package:manajemen_obat/presentation/auth/login_screen.dart';
import 'package:manajemen_obat/presentation/home/notifikasi_obat.dart';
import 'package:manajemen_obat/presentation/profil/dokter_profil_screen.dart';

class DokterHomeScreen extends StatefulWidget {
  const DokterHomeScreen({super.key});

  @override
  State<DokterHomeScreen> createState() => _DokterHomeScreenState();
}

class _DokterHomeScreenState extends State<DokterHomeScreen> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? doctorData;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final userDataString = await _secureStorage.read(key: 'userData');
      if (userDataString != null) {
        doctorData = jsonDecode(userDataString);
      } else {
        errorMessage = "Data dokter tidak ditemukan. Silakan login ulang.";
      }
    } catch (e) {
      errorMessage = 'Terjadi kesalahan saat memuat data dokter: $e';
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage != null)
      return Center(child: Text("Error: $errorMessage"));

    if (doctorData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard Dokter')),
        body: const Center(
          child: Text("Gagal memuat data dokter. Mohon login kembali."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Dokter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _secureStorage.delete(key: 'authToken');
              await _secureStorage.delete(key: 'userRole');
              await _secureStorage.delete(key: 'userData');
              context.pushAndRemoveUntil(const LoginScreen(), (route) => false);
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang, ${doctorData!['name'] ?? doctorData!['username'] ?? 'Dokter'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Spesialisasi: ${doctorData!['specialization'] ?? 'Tidak Tersedia'}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            _buildFeatureCard(
              context,
              icon: Icons.person_add_alt_1_outlined,
              title: 'Kelola Pasien & Obat',
              subtitle:
                  'Hubungkan diri Anda dengan pasien baru atau kelola daftar pasien yang sudah terdaftar.',
              onTap: () {
                context.push(const PatientManagementPage());
              },
            ),

            _buildFeatureCard(
              context,
              icon: Icons.notifications_active_outlined,
              title: 'Pengaturan Notifikasi Obat',
              subtitle:
                  'Atur jadwal dan pengingat konsumsi obat otomatis untuk pasien Anda.',
              onTap: () {
                context.push(const NotifikasiObat());
              },
            ),
            _buildFeatureCard(
              context,
              icon: Icons.person_outline,
              title: 'Profil Saya',
              subtitle:
                  'Lihat dan perbarui informasi profil pribadi Anda (nama, spesialisasi, kontak).',
              onTap: () {
                context.push(const DokterProfileScreen());
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
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
