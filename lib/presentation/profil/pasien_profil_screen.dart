import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:manajemen_obat/data/models/response/login_response_model.dart';

class PasienProfileScreen extends StatefulWidget {
  const PasienProfileScreen({super.key});

  @override
  State<PasienProfileScreen> createState() => _PasienProfileScreenState();
}

class _PasienProfileScreenState extends State<PasienProfileScreen> {
  bool isLoading = true;
  String? errorMessage;
  User? currentUserData;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final userDataString = await _secureStorage.read(key: 'userData');
      if (userDataString != null) {
        final Map<String, dynamic> userMap = jsonDecode(userDataString);
        setState(() {
          currentUserData = User.fromMap(userMap);
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profil Pasien")),
        body: Center(child: Text("Error: $errorMessage")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profil Pasien")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            currentUserData == null
                ? const Text("Data pengguna tidak ditemukan.")
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Nama: ${currentUserData!.username ?? 'N/A'}"),
                    Text("Role: ${currentUserData!.role ?? 'N/A'}"),
                    Text(
                      "ID Pasien: ${currentUserData!.idPasien ?? 'Tidak tersedia'}",
                    ),
                  ],
                ),
      ),
    );
  }
}
