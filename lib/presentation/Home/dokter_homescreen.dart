import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:manajemen_obat/core/core.dart';
import 'package:manajemen_obat/presentation/Home/patient_management_page.dart';
import 'package:manajemen_obat/presentation/auth/login_screen.dart';
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
}
