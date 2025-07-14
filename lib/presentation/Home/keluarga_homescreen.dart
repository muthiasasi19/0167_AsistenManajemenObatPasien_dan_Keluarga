import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:developer';
import 'package:manajemen_obat/core/core.dart';
import 'package:manajemen_obat/core/components/spaces.dart';
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
  // Data pasien terhubung akan langsung diambil dari FamilyBloc state.

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Controller untuk dialog koneksi pasien
  final TextEditingController _connectPatientIdController =
      TextEditingController();
  final GlobalKey<FormState> _connectPatientFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Memuat data profil keluarga dan daftar pasien terhubung saat inisialisasi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyBloc>().add(const LoadFamilyDataRequested());
      // memastikan daftar pasien dimuat saat layar pertama kali dibuka.
      context.read<FamilyBloc>().add(const LoadConnectedPatientsRequested());
    });
  }

  @override
  void dispose() {
    _connectPatientIdController.dispose();
    super.dispose();
  }

  // Helper method untuk styling InputDecoration secara konsisten
  InputDecoration _inputDecoration(
    String labelText, {
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        color: AppColors.grey,
      ), // Consistent grey label
      floatingLabelStyle: const TextStyle(
        color: AppColors.deepPurple,
        fontWeight: FontWeight.bold,
      ), // Bold and purple when floating
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0), // Rounded corners
        borderSide: const BorderSide(
          color: AppColors.light,
        ), // Lighter grey border for cleaner look
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(
          color: AppColors.light,
        ), // Lighter grey border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(
          color: AppColors.deepPurple, // Deep purple border when focused
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(
          color: AppColors.red, // Red border for errors
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.red, width: 2.0),
      ),
      filled: true,
      fillColor: AppColors.white, // White fill for text fields
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
        horizontal: 16.0,
      ),
    );
  }

  // Dialog untuk menghubungkan pasien baru
  Future<void> _showConnectPatientDialog(BuildContext dialogContext) async {
    _connectPatientIdController
        .clear(); // Bersihkan input setiap kali dialog dibuka

    await showDialog(
      context: dialogContext,
      builder: (context) {
        return BlocListener<FamilyBloc, FamilyState>(
          listener: (listenerContext, state) {
            if (state is PatientConnectionSuccess) {
              ScaffoldMessenger.of(
                listenerContext,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              Navigator.pop(listenerContext); // Tutup dialog
              // FITUR MAPS: Setelah pasien berhasil dihubungkan, minta Bloc untuk me-refresh daftar pasien.
              listenerContext.read<FamilyBloc>().add(
                const LoadConnectedPatientsRequested(),
              );
            } else if (state is PatientConnectionFailure) {
              ScaffoldMessenger.of(
                listenerContext,
              ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
            }
          },
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ), // More rounded dialog corners
            titlePadding: const EdgeInsets.fromLTRB(
              24.0,
              24.0,
              24.0,
              16.0,
            ), // More padding for title
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 10.0,
            ), // Consistent content padding
            actionsPadding: const EdgeInsets.fromLTRB(
              16.0,
              0,
              16.0,
              16.0,
            ), // Consistent actions padding
            title: const Text(
              'Hubungkan Pasien Baru',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.black,
                fontSize: 22,
              ), // Larger, bolder black title
            ),
            content: Form(
              key: _connectPatientFormKey,
              child: TextFormField(
                controller: _connectPatientIdController,
                decoration: _inputDecoration(
                  'ID Unik Pasien (contoh: PSN...)',
                  prefixIcon: const Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.grey,
                  ), // Grey scanner icon
                ),
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
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.grey, // Grey text
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ), // Slightly bolder text
                ),
                child: const Text('Batal'),
              ),
              BlocBuilder<FamilyBloc, FamilyState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed:
                        // Asumsi PatientConnecting adalah state yang valid dari FamilyBloc Anda untuk menunjukkan proses koneksi.
                        // Jika tidak ada, ganti dengan state loading yang sesuai dari FamilyBloc Anda.
                        state is PatientConnecting
                            ? null // Disable tombol saat sedang loading
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.deepPurple, // Custom deep purple button
                      foregroundColor: AppColors.white, // White text
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ), // More rounded button
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.lightSheet, // Light background for overall page
      appBar: AppBar(
        // Set AppBar background explicitly to deepPurple
        backgroundColor: AppColors.deepPurple,
        elevation: 0, // No shadow
        title: const Text(
          'Dashboard Keluarga',
          style: TextStyle(
            color: AppColors.white, // Title color is white for contrast
            fontWeight: FontWeight.w900, // Extra bold title
            fontSize: 24, // Larger title for prominence
            letterSpacing: 1.2, // Slight letter spacing for style
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ), // Icons are white
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 28), // Larger logout icon
            onPressed: () async {
              // This onPressed is now correctly functional as AppBar is top-level
              await _secureStorage.deleteAll(); // Ensure all data is cleared
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
      body: Stack(
        // Using Stack for layered, dynamic background and foreground elements
        children: [
          // Background Gradient/Wave (Top Section)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 280, // Height of the purple wave/area
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.deepPurple.withOpacity(0.9), // Darker start
                    AppColors.deepPurple.withOpacity(0.6), // Lighter end
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                // Organic, irregular shape for the bottom edge
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.elliptical(500, 150),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepPurple.withOpacity(0.6),
                    blurRadius:
                        30, // Increased blur for a softer, glowing effect
                    offset: const Offset(0, 15), // More pronounced shadow
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Content
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: () async {
                // FITUR MAPS: Saat refresh, pastikan kedua event dipanggil.
                context.read<FamilyBloc>().add(const LoadFamilyDataRequested());
                context.read<FamilyBloc>().add(
                  const LoadConnectedPatientsRequested(),
                );
              },
              color: AppColors.white, // White indicator on purple background
              backgroundColor: AppColors.deepPurple, // Background of indicator
              child: SingleChildScrollView(
                // Adjust top padding to leave space for the curved background and initial part of the welcome card
                padding: const EdgeInsets.only(
                  top: 100,
                  left: 24.0,
                  right: 24.0,
                  bottom: 24.0,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .center, // Center the family welcome card
                  children: [
                    // Welcome message section - now a distinct, floating card
                    BlocBuilder<FamilyBloc, FamilyState>(
                      buildWhen:
                          (previous, current) =>
                              current is FamilyLoaded || current is FamilyError,
                      builder: (context, state) {
                        if (state is FamilyLoaded &&
                            state.familyUserData != null) {
                          _familyUserData =
                              state.familyUserData; // Update user data
                          return Container(
                            // Fixed size for a perfect circle/oval for the family welcome card
                            height:
                                MediaQuery.of(context).size.width *
                                0.55, // Adjusted height to make it more circular/oval based on width
                            width:
                                MediaQuery.of(context).size.width *
                                0.55, // Adjusted width for oval shape
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 25,
                            ), // Adjusted padding to fit content better
                            decoration: BoxDecoration(
                              color: AppColors.white, // Solid white background
                              shape:
                                  BoxShape.circle, // Make it a perfect circle
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withOpacity(
                                    0.18,
                                  ), // Stronger shadow for floating effect
                                  blurRadius: 25, // More blur
                                  offset: const Offset(
                                    0,
                                    12,
                                  ), // More vertical offset
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.deepPurple,
                                width: 2.5,
                              ), // Prominent deep purple border
                            ),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center, // Center content vertically
                              mainAxisSize: MainAxisSize.min, // Wrap content
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .center, // Center text horizontally within the card
                              children: [
                                Text(
                                  'Halo,',
                                  style: TextStyle(
                                    fontSize:
                                        16, // Slightly smaller for better fit
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _familyUserData!.namaKeluarga ??
                                      _familyUserData!.username ??
                                      'Anggota Keluarga',
                                  style: const TextStyle(
                                    fontSize:
                                        22, // Adjusted size for circular card
                                    fontWeight:
                                        FontWeight
                                            .w900, // Extra bold for strong impact
                                    color:
                                        AppColors
                                            .deepPurple, // Deep purple for emphasis
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_familyUserData!.idKeluarga != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'ID Keluarga Anda: ${_familyUserData!.idKeluarga}',
                                    style: const TextStyle(
                                      fontSize:
                                          14, // Adjusted size for better fit
                                      color: AppColors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 6),
                                const Text(
                                  'Pantau kesehatan anggota keluarga Anda di sini.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.grey,
                                  ), // Adjusted size for better fit
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        } else if (state is FamilyError) {
                          log(
                            'KeluargaHomeScreen: FamilyError: ${state.message}',
                          );
                          return Container(
                            // Error card styling
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(color: AppColors.red),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Gagal memuat data profil keluarga. Mohon pastikan Anda sudah login dengan akun keluarga yang valid. Error: ${state.message}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.red,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<FamilyBloc>().add(
                                      const LoadFamilyDataRequested(),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.red,
                                    foregroundColor: AppColors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink(); // Fallback for initial/other states
                      },
                    ),
                    const SizedBox(height: 35), // Spacing after welcome card
                    // Feature Card: Connect New Patient
                    _buildFeatureCard(
                      context,
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'Hubungkan Pasien Baru',
                      subtitle:
                          'Tambahkan pasien yang ingin Anda pantau dengan kode unik pasien (PSN...).',
                      onTap: () => _showConnectPatientDialog(context),
                    ),
                    const SizedBox(height: 20), // Spacing between cards
                    // "Pasien yang Terhubung" Section Title
                    Align(
                      alignment: Alignment.centerLeft, // Align title to left
                      child: Text(
                        'Pasien yang Terhubung',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10), // Spacing below title
                    // Connected Patients List (BlocBuilder)
                    BlocBuilder<FamilyBloc, FamilyState>(
                      //  FITUR MAPS: Tambahkan PatientConnectionSuccess ke buildWhen
                      // agar widget ini direbuild setelah event koneksi berhasil.
                      buildWhen: (previous, current) {
                        return current is ConnectedPatientsLoaded ||
                            current is ConnectedPatientsError ||
                            current is ConnectedPatientsLoading ||
                            current
                                is PatientConnectionSuccess; // Menambahkan ini
                      },
                      builder: (context, state) {
                        if (state is ConnectedPatientsLoading) {
                          log(
                            'KeluargaHomeScreen: Displaying connected patients loading. State: ${state.runtimeType}',
                          );
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.deepPurple,
                                ), // Deep purple loading
                              ),
                            ),
                          );
                        }
                        // PERBAIKAN PENTING 6 - FITUR MAPS: Membaca daftar pasien dari state
                        else if (state is ConnectedPatientsLoaded) {
                          log(
                            'KeluargaHomeScreen: ConnectedPatientsLoaded with ${state.patients.length} patients.', // KOREKSI: Menggunakan state.patients
                          );
                          final List<FamilyConnectedPatientData>
                          connectedPatients =
                              state
                                  .patients; // KOREKSI: Langsung gunakan properti patients dari state

                          if (connectedPatients.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Belum ada pasien yang terhubung. Hubungkan pasien baru di atas.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(), // Important for nested scroll views
                            itemCount: connectedPatients.length,
                            itemBuilder: (context, index) {
                              final patient = connectedPatients[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                elevation: 6.0, // Increased elevation
                                shadowColor: AppColors.deepPurple.withOpacity(
                                  0.2,
                                ), // Soft shadow
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    16.0,
                                  ), // Rounded corners
                                  side: const BorderSide(
                                    color: AppColors.light,
                                    width: 0.5,
                                  ), // Subtle border
                                ),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.fromLTRB(
                                    20,
                                    10,
                                    20,
                                    10,
                                  ), // Adjusted padding
                                  leading: Container(
                                    padding: const EdgeInsets.all(
                                      8.0,
                                    ), // Padding for icon background
                                    decoration: BoxDecoration(
                                      color: AppColors.deepPurple.withOpacity(
                                        0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: AppColors.deepPurple,
                                      size: 30,
                                    ), // Deep purple icon
                                  ),
                                  title: Text(
                                    patient.nama ??
                                        'Nama Pasien Tidak Diketahui',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'ID Unik: ${patient.idUnik ?? 'N/A'}',
                                    style: const TextStyle(
                                      color: AppColors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  childrenPadding: const EdgeInsets.all(
                                    20.0,
                                  ), // Padding for expanded content
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRow(
                                          'Tanggal Lahir',
                                          patient.tanggalLahir != null
                                              ? DateFormat(
                                                'dd MMMM yyyy',
                                              ).format(
                                                DateTime.parse(
                                                  patient.tanggalLahir!,
                                                ),
                                              )
                                              : 'N/A',
                                          Icons.cake_outlined,
                                        ),
                                        _buildDetailRow(
                                          'Jenis Kelamin',
                                          patient.jenisKelamin ?? 'N/A',
                                          Icons.transgender_outlined,
                                        ),
                                        _buildDetailRow(
                                          'No. Telepon',
                                          patient.nomorTelepon ?? 'N/A',
                                          Icons.phone_outlined,
                                        ),
                                        _buildDetailRow(
                                          'Alamat',
                                          patient.alamat ?? 'N/A',
                                          Icons.location_city_outlined,
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ), // More spacing before buttons
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildSmallFeatureButton(
                                              context,
                                              icon: Icons.medication_outlined,
                                              label: 'Obat',
                                              onTap: () {
                                                if (patient.idGlobal != null &&
                                                    patient.idUnik != null) {
                                                  context.push(
                                                    MedicationPage(
                                                      patientGlobalId:
                                                          patient.idGlobal!,
                                                      initialPatientUniqueId:
                                                          patient.idUnik!,
                                                      isFamilyRole: true,
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'ID Global Pasien atau ID Unik tidak tersedia.',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                            _buildSmallFeatureButton(
                                              context,
                                              icon: Icons.history_edu_outlined,
                                              label: 'Riwayat',
                                              onTap: () {
                                                if (patient.idGlobal != null &&
                                                    patient.idUnik != null) {
                                                  context.push(
                                                    MedicationPage(
                                                      patientGlobalId:
                                                          patient.idGlobal!,
                                                      initialPatientUniqueId:
                                                          patient.idUnik!,
                                                      isHistory: true,
                                                      isFamilyRole: true,
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'ID Pasien tidak tersedia untuk fitur ini.',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                            // FITUR MAPS: Tombol untuk melihat lokasi pasien
                                            _buildSmallFeatureButton(
                                              context,
                                              icon: Icons.location_on_outlined,
                                              label: 'Lokasi',
                                              onTap: () {
                                                if (patient.idGlobal != null) {
                                                  context.push(
                                                    PasienLocationPage(
                                                      patientGlobalId:
                                                          patient.idGlobal!,
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'ID Global Pasien tidak tersedia.',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        } else if (state is ConnectedPatientsError) {
                          log(
                            'KeluargaHomeScreen: ConnectedPatientsError: ${state.message}',
                          );
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.warning_amber,
                                    color: AppColors.redCustom,
                                    size: 48,
                                  ), // Warning icon
                                  const SizedBox(height: 16),
                                  Text(
                                    'Gagal memuat pasien: ${state.message}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.redCustom,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<FamilyBloc>().add(
                                        const LoadConnectedPatientsRequested(),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.deepPurple,
                                      foregroundColor: AppColors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        // FITUR MAPS: Tambahkan fallback default untuk state awal atau tak terduga.
                        // Ini akan menampilkan pesan 'Memuat data pasien terhubung...' saat pertama kali atau state lain.
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Memuat data pasien terhubung...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30), // Spacing before profile card
                    // Feature Card: My Profile
                    _buildFeatureCard(
                      context,
                      icon: Icons.person_pin_outlined,
                      title: 'Profil Saya',
                      subtitle:
                          'Lihat dan perbarui informasi profil pribadi Anda.',
                      onTap: () {
                        context.push(const KeluargaProfileScreen());
                      },
                    ),
                    const SizedBox(height: 40), // More spacing at the bottom
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pembangun kartu fitur besar (reused and enhanced from DokterHomeScreen)
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 8.0, // Reduced vertical margin slightly
        horizontal: 0.0,
      ),
      elevation: 10.0, // Slightly reduced elevation for feature cards
      shadowColor: AppColors.deepPurple.withOpacity(
        0.4,
      ), // Stronger, yet soft purple shadow for depth
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20.0,
        ), // Slightly reduced border radius
        side: const BorderSide(
          color: AppColors.light,
          width: 0.8,
        ), // Slightly thicker light border
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          20.0,
        ), // Match card border radius for ripple effect
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 22.0,
            vertical: 20.0,
          ), // Reduced padding slightly
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(
                  12.0,
                ), // Reduced icon container padding
                decoration: BoxDecoration(
                  color: AppColors.deepPurple.withOpacity(
                    0.2,
                  ), // Consistent opacity for icon background
                  shape: BoxShape.circle, // Circular background for the icon
                  boxShadow: [
                    BoxShadow(
                      // Subtle shadow for the icon container
                      color: AppColors.deepPurple.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 36, // Slightly reduced icon size
                  color: AppColors.deepPurple,
                ),
              ),
              const SizedBox(
                width: 18,
              ), // Slightly reduced spacing between icon and text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20, // Reduced font size for card title
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ), // Spacing between title and subtitle
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15, // Reduced font size for subtitles
                        color: AppColors.grey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.light,
                size: 22, // Slightly reduced arrow icon size
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pembangun tombol fitur kecil di dalam ExpansionTile (enhanced)
  Widget _buildSmallFeatureButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0), // More rounded
          child: Container(
            padding: const EdgeInsets.all(10.0), // Adjusted padding
            decoration: BoxDecoration(
              color: AppColors.deepPurple.withOpacity(
                0.1,
              ), // Lighter background
              borderRadius: BorderRadius.circular(
                16.0,
              ), // Consistent rounded corners
              border: Border.all(
                color: AppColors.deepPurple.withOpacity(0.3),
                width: 0.5,
              ), // Subtle border
            ),
            child: Icon(
              icon,
              size: 30, // Consistent icon size
              color: AppColors.deepPurple, // Custom deep purple color
            ),
          ),
        ),
        const SizedBox(height: 4), // Reduced spacing
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grey, // Grey text
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Helper untuk menampilkan detail pasien dalam ExpansionTile (enhanced)
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6.0,
      ), // Adjusted vertical padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.deepPurple,
          ), // Custom deep purple icon
          const SizedBox(width: 10), // Adjusted spacing
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.black,
              ), // Black text
            ),
          ),
        ],
      ),
    );
  }
}
