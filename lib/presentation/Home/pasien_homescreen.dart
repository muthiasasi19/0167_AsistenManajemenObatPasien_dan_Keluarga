// lib/presentation/Home/pasien_homescreen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manajemen_obat/presentation/auth/login_screen.dart';
import 'package:manajemen_obat/presentation/Home/medication_page.dart';
import 'package:manajemen_obat/presentation/profil/pasien_profil_screen.dart';
import 'package:manajemen_obat/core/core.dart'; // Import AppColors and other core utilities
import 'package:manajemen_obat/core/components/spaces.dart'; // Import spaces if used
import 'dart:developer' as developer;
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:manajemen_obat/presentation/in_app_reminder/bloc/in_app_reminder_bloc.dart';
import 'package:manajemen_obat/data/models/response/doctor_response_model.dart';
import 'package:manajemen_obat/data/models/response/login_response_model.dart';
import 'package:manajemen_obat/presentation/pasien/bloc/patient_bloc.dart'; // Pastikan path ini benar (p_asien bukan P_asien)
import 'package:manajemen_obat/presentation/patient_location/bloc/patient_location_bloc.dart';

class PasienHomeScreen extends StatefulWidget {
  const PasienHomeScreen({super.key});

  @override
  State<PasienHomeScreen> createState() => _PasienHomeScreenState();
}

class _PasienHomeScreenState extends State<PasienHomeScreen> {
  User? currentUserData;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Timer?
  _locationTimer; // FITUR MAPS: Deklarasi Timer untuk pembaruan lokasi berkala
  Timer? _reminderTimer; // Timer untuk pengingat in-app
  bool _isReminderDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserDataAndFetchConnectedDoctor();
      _startLocationUpdates();
      _initializeInAppReminders();
    });
  }

  @override
  void dispose() {
    // FITUR MAPS: Pastikan timer dibatalkan saat widget dihapus untuk mencegah memory leaks
    _locationTimer?.cancel();
    _reminderTimer?.cancel(); // Batalkan timer pengingat notifikais
    super.dispose();
  }

  Future<void> _loadUserDataAndFetchConnectedDoctor() async {
    try {
      final userDataString = await _secureStorage.read(key: 'userData');
      if (userDataString != null) {
        final Map<String, dynamic> userMap = jsonDecode(userDataString);
        setState(() {
          currentUserData = User.fromMap(userMap);
        });

        if (currentUserData != null && currentUserData!.idPasien != null) {
          context.read<PatientBloc>().add(const GetConnectedDoctorRequested());
        } else {
          print(
            "PasienHomeScreen: Data ID pasien tidak ditemukan setelah login.",
          );
        }
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('PasienHomeScreen: Error saat memuat data user: $e');
    }
  }

  // FITUR MAPS: Fungsi untuk memeriksa dan meminta izin lokasi perangkat
  // FUNGSI INI HARUS ADA DI SINI AGAR TIDAK ADA ERROR 'NOT DEFINED'
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah layanan lokasi (GPS) aktif di perangkat
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Layanan lokasi dinonaktifkan. Harap aktifkan layanan lokasi.',
          ),
        ),
      );
      return false;
    }

    // Cek status izin lokasi aplikasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Jika izin ditolak, minta izin ke pengguna
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Jika izin tetap ditolak setelah permintaan
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak secara permanen.')),
        );
        return false;
      }
    }

    // Jika izin ditolak selamanya oleh pengguna (don't ask again)
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin lokasi ditolak secara permanen. Kami tidak dapat meminta izin.',
          ),
        ),
      );
      return false;
    }
    // Jika izin diberikan
    return true;
  }

  // FITUR MAPS: Fungsi untuk mendapatkan lokasi terkini dan mengirimkannya ke backend melalui Bloc
  Future<void> _getCurrentAndSendLocation({bool showSnackbar = true}) async {
    final hasPermission =
        await _handleLocationPermission(); // Panggilan ke fungsi yang sudah ada
    if (!hasPermission) {
      developer.log(
        'FITUR MAPS: Izin lokasi tidak diberikan atau layanan tidak aktif.',
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      developer.log(
        'FITUR MAPS: Lokasi Pasien: Lat ${position.latitude}, Long ${position.longitude}',
      );

      // Kirim event ke PatientLocationBloc
      context.read<PatientLocationBloc>().add(
        SendPatientLocationRequested(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );

      // Tampilkan SnackBar untuk menandakan proses pengiriman dimulai (jika diizinkan)
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mengirim lokasi...'),
            backgroundColor: AppColors.deepPurple, // Warna informatif
          ),
        );
      }
    } catch (e) {
      // Tangani error jika terjadi masalah saat mendapatkan lokasi (sebelum dikirim)
      developer.log('FITUR MAPS: Error saat mendapatkan lokasi: $e');
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat mendapatkan lokasi: $e'),
            backgroundColor: AppColors.redCustom,
          ),
        );
      }
    }
  }

  // FITUR MAPS: Metode untuk memulai timer pembaruan lokasi berkala
  void _startLocationUpdates() {
    // Kirim lokasi satu kali segera setelah fungsi ini dipanggil
    // Ini akan menampilkan "Mengirim lokasi..." SnackBar
    _getCurrentAndSendLocation(showSnackbar: true);

    // Atur timer untuk mengirim lokasi secara berkala
    _locationTimer = Timer.periodic(
      const Duration(
        seconds: 30, // Interval pengiriman lokasi (misal: setiap 30 detik)
      ),
      (timer) {
        // Panggil fungsi pengiriman lokasi, tapi tanpa menampilkan SnackBar setiap kali jika pengiriman otomatis.
        _getCurrentAndSendLocation(showSnackbar: false);
      },
    );
  }

  // TAMBAH NOTIFIKASI
  void _initializeInAppReminders() {
    // Muat jadwal pengingat saat ini dari backend
    context.read<InAppReminderBloc>().add(const LoadMyNotificationSchedules());

    // Mulai timer untuk memeriksa pengingat setiap 15-30 detik (sesuaikan interval)
    _reminderTimer = Timer.periodic(
      const Duration(seconds: 20), // Periksa setiap 20 detik
      (timer) {
        context.read<InAppReminderBloc>().add(const CheckForInAppReminders());
      },
    );
  }

  void _showInAppReminderDialog(
    String medicationName,
    String dosage,
    String scheduledTime,
    String reminderType,
  ) {
    if (_isReminderDialogShowing) {
      developer.log("Reminder dialog is already showing. Skipping.");
      return; // Hindari menampilkan dialog ganda
    }

    setState(() {
      _isReminderDialogShowing = true;
    });

    String title;
    Color iconColor;
    IconData icon;

    if (reminderType == 'early') {
      title = 'Pengingat Awal!';
      iconColor = AppColors.blueLight;
      icon = Icons.alarm;
    } else {
      // 'on_time'
      title = 'Waktunya Minum Obat!';
      iconColor = AppColors.deepPurple;
      icon = Icons.medication;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // User must interact to dismiss
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(icon, color: iconColor, size: 30),
              const SpaceWidth(10),
              Flexible(
                // Use Flexible to prevent overflow
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Obat: $medicationName\nDosis: $dosage\nJadwal: $scheduledTime',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _isReminderDialogShowing = false;
                });
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: AppColors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _isReminderDialogShowing =
            false; // Reset flag after dialog is dismissed
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserData == null) {
      return Scaffold(
        backgroundColor: AppColors.lightSheet,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.deepPurple),
          ),
        ),
      );
    }

    // Wrap Scaffold dengan BlocListener untuk mendengarkan state dari PatientLocationBloc
    return MultiBlocListener(
      listeners: [
        BlocListener<PatientLocationBloc, PatientLocationState>(
          listener: (context, state) {
            if (state is SendLocationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lokasi berhasil dikirim ke keluarga!'),
                  backgroundColor: AppColors.deepPurple,
                ),
              );
            } else if (state is SendLocationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal mengirim lokasi: ${state.message}'),
                  backgroundColor: AppColors.redCustom,
                ),
              );
            }
          },
        ),

        BlocListener<InAppReminderBloc, InAppReminderState>(
          listener: (context, state) {
            if (state is ShowInAppReminder) {
              developer.log(
                "PasienHomeScreen: Received ShowInAppReminder state for ${state.medicationName} at ${state.scheduledTime}",
              );
              _showInAppReminderDialog(
                state.medicationName,
                state.medicationDosage,
                state.scheduledTime,
                state.reminderType,
              );
            } else if (state is InAppReminderError) {
              developer.log(
                "PasienHomeScreen: InAppReminder Error: ${state.message}",
              );
              // Opsi: Tampilkan SnackBar atau pesan error kecil jika diinginkan
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pengingat error: ${state.message}'),
                  backgroundColor: AppColors.redCustom,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.lightSheet,
        appBar: AppBar(
          title: const Text(
            'Dashboard Pasien',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: AppColors.deepPurple,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _secureStorage.delete(key: 'authToken');
                await _secureStorage.delete(key: 'userRole');
                await _secureStorage.delete(key: 'userData');
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
        body: RefreshIndicator(
          onRefresh: () async {
            await _loadUserDataAndFetchConnectedDoctor();
            _initializeInAppReminders(); // Muat ulang pengingat juga saat refresh
          },
          color: AppColors.deepPurple,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${currentUserData!.username ?? 'Pasien'}!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selamat datang di aplikasi Asisten Manajemen Obat.',
                  style: TextStyle(fontSize: 16, color: AppColors.grey),
                ),
                const SizedBox(height: 30),
                BlocBuilder<PatientBloc, PatientState>(
                  builder: (context, state) {
                    DoctorData? displayedDoctor;
                    String? displayMessage;

                    if (state is ConnectedDoctorLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.deepPurple,
                          ),
                        ),
                      );
                    } else if (state is ConnectedDoctorLoaded) {
                      displayedDoctor = state.doctorData;
                    } else if (state is ConnectedDoctorError) {
                      displayMessage = state.message;
                    } else {
                      displayMessage = 'Memuat status koneksi dokter...';
                    }

                    return _buildConnectedDoctorSection(
                      context,
                      displayedDoctor,
                      displayMessage,
                    );
                  },
                ),
                const SizedBox(height: 30),
                // FITUR MAPS: Kartu UI baru untuk mengirim lokasi secara manual
                _buildFeatureCard(
                  context,
                  icon: Icons.location_on_outlined,
                  title: 'Kirim Lokasi Saya',
                  subtitle:
                      'Kirim lokasi terkini Anda kepada keluarga yang terhubung.',
                  onTap: () {
                    // Panggil fungsi pengiriman lokasi dengan SnackBar
                    _getCurrentAndSendLocation(showSnackbar: true);
                  },
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  context,
                  icon: Icons.access_time_outlined,
                  title: 'Jadwal Konsumsi Obat',
                  subtitle:
                      'Lihat jadwal obat Anda dan tandai yang sudah diminum.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const MedicationPage(isPatientRole: true),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  context,
                  icon: Icons.history_edu_outlined,
                  title: 'Riwayat Konsumsi Obat',
                  subtitle: 'Periksa riwayat obat yang sudah Anda minum.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const MedicationPage(
                              isHistory: true,
                              isPatientRole: true,
                            ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  context,
                  icon: Icons.person_outline,
                  title: 'Profil Saya',
                  subtitle: 'Lihat dan perbarui informasi profil pribadi Anda.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PasienProfileScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bagian _buildConnectedDoctorSection dan _buildFeatureCard (tidak ada perubahan)
  Widget _buildConnectedDoctorSection(
    BuildContext context,
    DoctorData? doctor,
    String? message,
  ) {
    if (doctor != null) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 6.0,
        shadowColor: AppColors.deepPurple.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: AppColors.light, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: AppColors.deepPurple.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.health_and_safety_outlined,
                      size: 32,
                      color: AppColors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Terhubung dengan Dokter:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                doctor.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Spesialisasi: ${doctor.specialization}',
                style: const TextStyle(fontSize: 15, color: AppColors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'Telp: ${doctor.phoneNumber}',
                style: const TextStyle(fontSize: 15, color: AppColors.grey),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 6.0,
        shadowColor: AppColors.redCustom.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: AppColors.light, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: AppColors.redCustom.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_off_outlined,
                      size: 32,
                      color: AppColors.redCustom,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Status Koneksi Dokter:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.redCustom,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                message ??
                    'Anda belum terhubung dengan dokter manapun. Dokter Anda dapat menghubungkan Anda menggunakan ID unik Anda (ID Pasien yang tersedia di halaman Profil).',
                style: const TextStyle(fontSize: 16, color: AppColors.grey),
              ),
            ],
          ),
        ),
      );
    }
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
      elevation: 6.0,
      shadowColor: AppColors.deepPurple.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: const BorderSide(color: AppColors.light, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: AppColors.deepPurple.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: AppColors.deepPurple),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
