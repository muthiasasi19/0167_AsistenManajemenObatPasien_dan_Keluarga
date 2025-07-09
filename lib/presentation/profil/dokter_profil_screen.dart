import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class DokterProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialUserData;

  const DokterProfileScreen({super.key, this.initialUserData});

  @override
  State<DokterProfileScreen> createState() => _DokterProfileScreenState();
}

class _DokterProfileScreenState extends State<DokterProfileScreen> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? userData;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

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
      if (widget.initialUserData != null) {
        userData = widget.initialUserData;
      } else {
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
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage != null)
      return Center(child: Text("Error: $errorMessage"));

    return Scaffold(
      appBar: AppBar(title: const Text("Profil Dokter")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            userData == null
                ? const Text("Data pengguna tidak ditemukan.")
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Username: ${userData!['username'] ?? 'N/A'}"),
                    Text("Role: ${userData!['role'] ?? 'N/A'}"),
                    Text(
                      "ID Dokter: ${userData!['id_dokter'] ?? 'Tidak tersedia'}",
                    ),
                    Text("Nama: ${userData!['name'] ?? 'Tidak tersedia'}"),
                    Text(
                      "Spesialisasi: ${userData!['specialization'] ?? 'Tidak tersedia'}",
                    ),
                    Text(
                      "Nomor Telepon: ${userData!['phoneNumber'] ?? 'Tidak tersedia'}",
                    ),
                    Text("Alamat: ${userData!['address'] ?? 'Tidak tersedia'}"),
                  ],
                ),
      ),
    );
  }
}
