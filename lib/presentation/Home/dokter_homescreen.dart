import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import 'package:manajemen_obat/core/core.dart'; // Ensure AppColors is accessible here
import 'package:manajemen_obat/core/components/spaces.dart'; // Ensure Spaces is accessible
import 'package:manajemen_obat/presentation/Home/patient_management_page.dart';
import 'package:manajemen_obat/presentation/auth/login_screen.dart';
import 'package:manajemen_obat/presentation/profil/dokter_profil_screen.dart';
import 'package:manajemen_obat/presentation/home/notifikasi_obat.dart';

class DokterHomeScreen extends StatefulWidget {
  const DokterHomeScreen({super.key});

  @override
  State<DokterHomeScreen> createState() => _DokterHomeScreenState();
}

class _DokterHomeScreenState extends State<DokterHomeScreen> {
  // State variables for loading and data
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? doctorData;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  // Method to load doctor data from secure storage
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
    // --- UI for Loading State ---
    // Displays a full-screen loading indicator while data is being fetched.
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.lightSheet, // Consistent background color
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.deepPurple,
            ), // Custom deep purple loading indicator
          ),
        ),
      );
    }

    // --- UI for Error State ---
    // Displays an error message and a retry button if data loading fails.
    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.lightSheet, // Consistent background color
        appBar: AppBar(
          title: const Text(
            'Dashboard Dokter',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: AppColors.deepPurple,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.red,
                  size: 48,
                ), // Red error icon
                const SizedBox(height: 16),
                Text(
                  "Error: $errorMessage",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.red,
                  ), // Red error text
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDoctorData, // Retry loading data
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.deepPurple, // Custom deep purple button
                    foregroundColor: AppColors.white, // White text
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- UI for Data Not Found State ---
    // Displays a message if doctorData is still null after loading attempts.
    if (doctorData == null) {
      return Scaffold(
        backgroundColor: AppColors.lightSheet, // Consistent background color
        appBar: AppBar(
          title: const Text(
            'Dashboard Dokter',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: AppColors.deepPurple,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.white),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Gagal memuat data dokter. Mohon login kembali.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey), // Grey text
            ),
          ),
        ),
      );
    }

    // --- Main Dashboard UI ---
    // Displays the doctor's personalized dashboard with feature cards.
    return Scaffold(
      backgroundColor:
          AppColors.lightSheet, // Light background for overall page
      // AppBar is now directly in Scaffold, no longer nested in a custom Container.
      appBar: AppBar(
        // Set AppBar background explicitly to deepPurple
        backgroundColor: AppColors.deepPurple,
        elevation: 0, // No shadow
        title: const Text(
          'Dashboard Dokter',
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
              await _secureStorage.delete(key: 'authToken');
              await _secureStorage.delete(key: 'userRole');
              await _secureStorage.delete(key: 'userData');
              context.pushAndRemoveUntil(const LoginScreen(), (route) => false);
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
              onRefresh:
                  _loadDoctorData, // Allows pull-to-refresh to reload data
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
                      CrossAxisAlignment.center, // Center the doctor name card
                  children: [
                    // Welcome message section - now a distinct, circular/oval floating card
                    Container(
                      width:
                          MediaQuery.of(context).size.width *
                          0.75, // Adjust width for oval shape
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 30,
                      ), // More generous vertical padding
                      decoration: BoxDecoration(
                        color: AppColors.white, // Solid white background
                        borderRadius: BorderRadius.circular(
                          100,
                        ), // Make it very rounded/oval
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(
                              0.15,
                            ), // Stronger shadow for floating effect
                            blurRadius: 20, // More blur
                            offset: const Offset(0, 10), // More vertical offset
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.deepPurple,
                          width: 2,
                        ), // Prominent deep purple border
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Wrap content
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .center, // Center text horizontally within the card
                        children: [
                          Text(
                            'Selamat Datang,',
                            style: TextStyle(
                              fontSize: 18, // Slightly smaller
                              fontWeight: FontWeight.w500,
                              color: AppColors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            doctorData!['name'] ??
                                doctorData!['username'] ??
                                'Dokter',
                            style: const TextStyle(
                              fontSize: 26, // Adjusted size
                              fontWeight:
                                  FontWeight
                                      .w900, // Extra bold for strong impact
                              color:
                                  AppColors
                                      .deepPurple, // Deep purple for emphasis
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Spesialisasi: ${doctorData!['specialization'] ?? 'Tidak Tersedia'}',
                            style: const TextStyle(
                              fontSize: 15, // Adjusted size
                              color: AppColors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 35,
                    ), // Increased spacing after welcome card
                    // Feature Cards Section
                    // Using Align.centerLeft to push cards to the left, but overall column is centered
                    // This creates a staggered/offset look if combined with a parent alignment
                    Align(
                      alignment:
                          Alignment
                              .center, // Changed to center to ensure cards are centered
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .center, // Align contents of this column to center
                        children: [
                          _buildFeatureCard(
                            context,
                            icon:
                                Icons
                                    .group_add_outlined, // More inviting icon for patient management
                            title: 'Kelola Pasien & Obat',
                            subtitle:
                                'Hubungkan diri Anda dengan pasien baru atau kelola daftar pasien yang sudah terdaftar.',
                            onTap: () {
                              context.push(const PatientManagementPage());
                            },
                          ),
                          const SizedBox(
                            height: 16,
                          ), // Consistent spacing between cards

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
                          const SizedBox(
                            height: 16,
                          ), // Consistent spacing between cards

                          _buildFeatureCard(
                            context,
                            icon:
                                Icons
                                    .person_pin_outlined, // More distinct profile icon
                            title: 'Profil Saya',
                            subtitle:
                                'Lihat dan perbarui informasi profil pribadi Anda (nama, spesialisasi, kontak).',
                            onTap: () {
                              context.push(const DokterProfileScreen());
                            },
                          ),
                        ],
                      ),
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

  // Widget builder for consistent and visually appealing feature cards
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
        ), // Consistent border
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
}
