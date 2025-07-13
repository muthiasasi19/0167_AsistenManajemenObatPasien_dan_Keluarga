import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import ini
import 'dart:convert'; // Untuk jsonDecode

class DokterProfileScreen extends StatefulWidget {
  // Terima data pengguna sebagai parameter
  final Map<String, dynamic>? initialUserData;

  const DokterProfileScreen({super.key, this.initialUserData});

  @override
  State<DokterProfileScreen> createState() => _DokterProfileScreenState();
}

class _DokterProfileScreenState extends State<DokterProfileScreen> {
  bool isLoading = true; // Akan false setelah data dimuat
  String? errorMessage;
  Map<String, dynamic>? userData;
  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage(); // Inisialisasi storage

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Memuat profil dari storage, bukan login ulang
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Prioritaskan data yang langsung diterima jika ada (dari argumen konstruktor)
      if (widget.initialUserData != null) {
        userData = widget.initialUserData;
      } else {
        // Jika tidak ada data awal, coba ambil dari secure storage
        final userDataString = await _secureStorage.read(key: 'userData');
        if (userDataString != null) {
          userData = jsonDecode(userDataString);
        } else {
          errorMessage = "Data profil tidak ditemukan. Silakan login ulang.";
        }
      }
    } catch (e) {
      errorMessage = 'Terjadi kesalahan saat memuat profil: $e';
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profil Dokter")),
        body: Center(child: Text("Error: $errorMessage")),
      );
    }

    // Pastikan userData tidak null sebelum mengakses propertinya
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profil Dokter")),
        body: const Center(child: Text("Data pengguna tidak ditemukan.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profil Dokter",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
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
              backgroundColor: Colors.blueAccent.withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 80,
                color: Colors.blueAccent.shade700,
              ),
            ),
            const SizedBox(height: 20),

            // Nama Dokter
            Text(
              userData!['name'] ?? 'Nama Dokter Tidak Diketahui',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),

            // Spesialisasi
            Text(
              userData!['specialization'] ?? 'Spesialisasi Tidak Tersedia',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
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
                      icon: Icons.badge,
                      label: "ID Dokter",
                      value: userData!['id_dokter'] ?? 'Tidak tersedia',
                    ),
                    _buildDivider(),
                    _buildProfileInfoRow(
                      icon:
                          Icons
                              .account_circle, // Menggunakan ikon yang lebih umum untuk username
                      label: "Username",
                      value: userData!['username'] ?? 'N/A',
                    ),
                    _buildDivider(),
                    _buildProfileInfoRow(
                      icon: Icons.medical_services,
                      label: "Role",
                      value: userData!['role'] ?? 'N/A',
                    ),
                    _buildDivider(),
                    _buildProfileInfoRow(
                      icon: Icons.phone,
                      label: "Nomor Telepon",
                      value: userData!['phoneNumber'] ?? 'Tidak tersedia',
                    ),
                    _buildDivider(),
                    _buildProfileInfoRow(
                      icon: Icons.location_on,
                      label: "Alamat",
                      value: userData!['address'] ?? 'Tidak tersedia',
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
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
      color: Colors.grey.shade300,
      thickness: 1,
      height: 20,
      indent: 40, // Sesuaikan dengan indentasi ikon
    );
  }
}
