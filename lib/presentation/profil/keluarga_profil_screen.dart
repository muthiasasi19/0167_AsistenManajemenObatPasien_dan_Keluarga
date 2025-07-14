import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeluargaProfileScreen extends StatefulWidget {
  const KeluargaProfileScreen({super.key});

  @override
  State<KeluargaProfileScreen> createState() => _KeluargaProfileScreenState();
}

class _KeluargaProfileScreenState extends State<KeluargaProfileScreen> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? userData;
  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage(); // Inisialisasi storage

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userDataString = await _secureStorage.read(key: 'userData');
      if (userDataString != null) {
        userData = jsonDecode(userDataString);
      } else {
        errorMessage = "Data profil tidak ditemukan. Silakan login ulang.";
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
        appBar: AppBar(title: const Text("Profil Keluarga")),
        body: Center(child: Text("Error: $errorMessage")),
      );
    }

    // Pastikan userData tidak null sebelum mengakses propertinya
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profil Keluarga")),
        body: const Center(child: Text("Data pengguna tidak ditemukan.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profil Keluarga",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
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
              backgroundColor: Colors.deepPurple.withOpacity(0.2),
              child: Icon(
                Icons.family_restroom, // Ikon untuk keluarga
                size: 80,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 20),

            // Nama Keluarga
            Text(
              userData!['username'] ??
                  'Nama Keluarga Tidak Diketahui', // Menggunakan username sebagai nama
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),

            // Role
            Text(
              userData!['role'] ?? 'Role Tidak Tersedia',
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
                      icon: Icons.vpn_key, // Ikon untuk ID unik keluarga
                      label: "ID Keluarga",
                      value: userData!['id_keluarga'] ?? 'Tidak tersedia',
                      iconColor: Colors.deepPurple,
                    ),
                    _buildDivider(),
                    _buildProfileInfoRow(
                      icon: Icons.person,
                      label: "Nama Lengkap",
                      value: userData!['nama'] ?? 'Tidak tersedia',
                      iconColor: Colors.deepPurple,
                    ),
                    _buildDivider(),
                    _buildProfileInfoRow(
                      icon: Icons.phone,
                      label: "Nomor Telepon",
                      value: userData!['nomor_telepon'] ?? 'Tidak tersedia',
                      iconColor: Colors.deepPurple,
                    ),
                    _buildDivider(),
                    _buildProfileInfoRow(
                      icon: Icons.location_on,
                      label: "Alamat",
                      value: userData!['alamat'] ?? 'Tidak tersedia',
                      iconColor: Colors.deepPurple,
                    ),
                    // Tambahkan detail lain sesuai kebutuhan Anda dari userData
                    // Pastikan kunci yang digunakan cocok dengan JSON dari backend
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
    Color iconColor = Colors.blueAccent, // Tambahkan parameter warna ikon
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
