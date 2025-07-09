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

  // Controller untuk  koneksi pasien
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
}
