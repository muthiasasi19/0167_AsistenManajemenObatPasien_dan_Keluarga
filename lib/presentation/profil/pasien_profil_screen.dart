import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import ini
import 'dart:convert'; // Import untuk jsonDecode
import 'package:manajemen_obat/data/models/response/login_response_model.dart'; // Import model User
import 'package:manajemen_obat/core/core.dart'; // Import AppColors

class PasienProfileScreen extends StatefulWidget {
  const PasienProfileScreen({super.key});

  @override
  State<PasienProfileScreen> createState() => _PasienProfileScreenState();
}

class _PasienProfileScreenState extends State<PasienProfileScreen> {
  bool isLoading = true;
  String? errorMessage;
  User? currentUserData; // Tetap bertipe User? sesuai permintaan

  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage(); // Inisialisasi storage

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Panggil fungsi untuk memuat data pengguna
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true; // Set loading saat memuat data
      errorMessage = null;
    });
    try {
      final userDataString = await _secureStorage.read(key: 'userData');
      if (userDataString != null) {
        final Map<String, dynamic> userMap = jsonDecode(userDataString);
        setState(() {
          currentUserData = User.fromMap(userMap); // Parse ke model User
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Data pengguna tidak ditemukan. Silakan login kembali.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan saat memuat data profil: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.lightSheet, // Use AppColors.lightSheet
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.deepPurple,
            ), // Use AppColors.deepPurple
          ),
        ),
      );
    }
    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.lightSheet, // Use AppColors.lightSheet
        appBar: AppBar(
          title: const Text(
            "Profil Pasien",
            style: TextStyle(color: AppColors.white), // Use AppColors.white
          ),
        ),
        body: Center(
          child: Text(
            "Error: $errorMessage",
            style: TextStyle(color: AppColors.red), // Use AppColors.red
          ),
        ),
      );
    }

    if (currentUserData == null) {
      return Scaffold(
        backgroundColor: AppColors.lightSheet, // Use AppColors.lightSheet
        appBar: AppBar(
          title: const Text(
            "Profil Pasien",
            style: TextStyle(color: AppColors.white), // Use AppColors.white
          ),
        ),
        body: const Center(
          child: Text(
            "Data pengguna tidak ditemukan.",
            style: TextStyle(color: AppColors.grey), // Use AppColors.grey
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightSheet, // Use AppColors.lightSheet
      appBar: AppBar(
        title: const Text(
          "Profil Pasien",
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ), // Use AppColors.white
        ),
        backgroundColor:
            AppColors
                .deepPurple, // Change from Colors.orange to AppColors.deepPurple
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Bagian Avatar Profil
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.deepPurple.withOpacity(
                0.2,
              ), // Change from Colors.orange.withOpacity(0.2) to AppColors.deepPurple.withOpacity(0.2)
              child: Icon(
                Icons.sick, // Ikon untuk pasien
                size: 80,
                color:
                    AppColors
                        .deepPurple, // Change from Colors.orange.shade700 to AppColors.deepPurple
              ),
            ),
            const SizedBox(height: 20),

            // Nama Pasien (menggunakan nama dari tabel pasien, jika ada di User model)
            Text(
              currentUserData!.namaPasien ??
                  currentUserData!.username ??
                  'Nama Pasien Tidak Diketahui',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.black, // Use AppColors.black
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),

            // Role (tetap ditampilkan dari User model)
            Text(
              currentUserData!.role ?? 'Role Tidak Tersedia',
              style: TextStyle(
                fontSize: 18,
                color:
                    AppColors
                        .grey, // Change from Colors.grey.shade700 to AppColors.grey
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Detail Informasi dalam Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    _buildProfileInfoRow(
                      icon: Icons.fingerprint, // Ikon untuk ID unik pasien
                      label: "ID Pasien Unik",
                      value:
                          currentUserData!.idPasien ??
                          'Tidak tersedia', // Menggunakan idPasien dari User model
                      iconColor:
                          AppColors
                              .deepPurple, // Change from Colors.orange to AppColors.deepPurple
                    ),
                    _buildDivider(),
                    _buildProfileInfoRow(
                      icon: Icons.calendar_today,
                      label: "Tanggal Lahir",
                      value:
                          currentUserData!.tanggalLahirPasien ??
                          'Tidak tersedia', // Asumsi ada di User model
                      iconColor:
                          AppColors
                              .deepPurple, // Change from Colors.orange to AppColors.deepPurple
                    ),
                    _buildDivider(),
                    _buildProfileInfoRow(
                      icon: Icons.wc,
                      label: "Jenis Kelamin",
                      value:
                          currentUserData!.jenisKelaminPasien ??
                          'Tidak tersedia', // Asumsi ada di User model
                      iconColor:
                          AppColors
                              .deepPurple, // Change from Colors.orange to AppColors.deepPurple
                    ),
                    _buildDivider(),
                    _buildProfileInfoRow(
                      icon: Icons.phone,
                      label: "Nomor Telepon",
                      value:
                          currentUserData!.nomorTeleponPasien ??
                          'Tidak tersedia', // Asumsi ada di User model
                      iconColor:
                          AppColors
                              .deepPurple, // Change from Colors.orange to AppColors.deepPurple
                    ),
                    _buildDivider(),
                    _buildProfileInfoRow(
                      icon: Icons.location_on,
                      label: "Alamat",
                      value:
                          currentUserData!.alamatPasien ??
                          'Tidak tersedia', // Asumsi ada di User model
                      iconColor:
                          AppColors
                              .deepPurple, // Change from Colors.orange to AppColors.deepPurple
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper method untuk membuat baris informasi profil
  Widget _buildProfileInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color iconColor =
        AppColors
            .deepPurple, // Change default from Colors.blueAccent to AppColors.deepPurple
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24), // Gunakan iconColor
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                  ), // Change from Colors.grey.shade600 to AppColors.grey
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black, // Use AppColors.black
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method untuk divider
  Widget _buildDivider() {
    return Divider(
      color:
          AppColors
              .stroke, // Change from Colors.grey.shade300 to AppColors.stroke
      thickness: 1,
      height: 20,
      indent: 40, // Sesuaikan dengan indentasi ikon
    );
  }
}
