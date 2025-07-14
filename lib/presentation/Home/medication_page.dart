import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manajemen_obat/core/components/spaces.dart';
import 'package:manajemen_obat/core/core.dart';
import 'package:manajemen_obat/data/models/request/medication/add_medication_request_model.dart';
import 'package:manajemen_obat/data/models/request/medication/update_medication_request_model.dart';
import 'package:manajemen_obat/data/models/response/medication_history_response_model.dart'
    show MedicationHistoryData;
import 'package:manajemen_obat/data/models/response/medication_response_model.dart';
import 'package:manajemen_obat/data/models/response/patient_search_result_model.dart';
import 'package:manajemen_obat/presentation/Home/image_viewer_page.dart';
import 'package:manajemen_obat/presentation/pasien/bloc/patient_bloc.dart';
import 'package:manajemen_obat/presentation/medication/bloc/medication_bloc.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manajemen_obat/service/service_http_client.dart';
import 'package:collection/collection.dart';
import 'dart:developer' as developer;

import 'package:manajemen_obat/data/models/response/login_response_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manajemen_obat/presentation/auth/login_screen.dart';

class MedicationPage extends StatefulWidget {
  final int? patientGlobalId;
  final String? initialPatientUniqueId;
  final bool isHistory;
  final bool isPatientRole;
  final bool isFamilyRole;

  final String? initialPatientName;

  const MedicationPage({
    super.key,
    this.patientGlobalId,
    this.initialPatientUniqueId,
    this.isHistory = false,
    this.isPatientRole = false,
    this.isFamilyRole = false,
    this.initialPatientName,
  });

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  final TextEditingController patientNameSearchController =
      TextEditingController();
  String? _currentSelectedPatientUniqueId;
  String? _currentSelectedPatientName;
  int? _currentSelectedPatientGlobalId;
  List<PatientSearchResult> _patientSearchResults = [];
  User? _currentUserData;
  final FocusNode _patientSearchFocusNode = FocusNode();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _selectedScheduleTypeDialog = 'daily_fixed_times';
  int _selectedDailyFrequencyDialog = 1; // Untuk 1x, 2x, 3x, 4x sehari
  List<TimeOfDay> _selectedTimesDialog = [TimeOfDay.now()];

  final TextEditingController _instructionsController = TextEditingController();

  File? _pickedImage; // State untuk menyimpan gambar yang dipilih
  final ImagePicker _picker = ImagePicker();

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

  @override
  void initState() {
    super.initState();
    _loadUserDataAndInitializeMedications();
    patientNameSearchController.addListener(_onPatientNameSearchChanged);
  }

  @override
  void dispose() {
    patientNameSearchController.removeListener(_onPatientNameSearchChanged);
    patientNameSearchController.dispose();
    _patientSearchFocusNode.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _onPatientNameSearchChanged() {
    if (patientNameSearchController.text.isEmpty &&
        (_currentSelectedPatientUniqueId != null ||
            _currentSelectedPatientGlobalId != null)) {
      _clearPatientSelection();
    }
  }

  Future<void> _loadUserDataAndInitializeMedications() async {
    final userDataString = await _secureStorage.read(key: 'userData');
    if (userDataString != null) {
      final userMap = jsonDecode(userDataString);
      setState(() {
        _currentUserData = User.fromMap(userMap);
      });

      if (widget.isPatientRole &&
          _currentUserData?.role?.toLowerCase() == 'pasien') {
        if (_currentUserData?.patientGlobalId != null &&
            _currentUserData?.idPasien != null) {
          _currentSelectedPatientGlobalId = _currentUserData!.patientGlobalId;
          _currentSelectedPatientUniqueId = _currentUserData!.idPasien;
          _currentSelectedPatientName =
              _currentUserData!.namaPasien ?? _currentUserData!.username ?? '';
          patientNameSearchController.text = _currentSelectedPatientName!;
          _loadMedicationsForPatient(
            patientGlobalId: _currentSelectedPatientGlobalId!,
            patientUniqueId: _currentSelectedPatientUniqueId!,
            isForSelfOrFamily: true,
          );
          developer.log(
            'MedicationPage: Dipanggil sebagai role Pasien sendiri. ID Global: ${_currentSelectedPatientGlobalId}, ID Unik: ${_currentSelectedPatientUniqueId}.',
          );
        } else {
          developer.log(
            'MedicationPage: ID Pasien atau ID Global Pasien tidak ditemukan di data user login.',
          );
          _clearMedicationsAndShowMessage();
        }
      } else if (widget.patientGlobalId != null) {
        _currentSelectedPatientGlobalId = widget.patientGlobalId;
        if (widget.initialPatientUniqueId != null) {
          _currentSelectedPatientUniqueId = widget.initialPatientUniqueId;
        } else {}

        _loadMedicationsForPatient(
          patientGlobalId: _currentSelectedPatientGlobalId!,
          patientUniqueId: _currentSelectedPatientUniqueId,
          isForSelfOrFamily: widget.isFamilyRole,
        );
        developer.log(
          'MedicationPage: Dipanggil dengan patientGlobalId: ${widget.patientGlobalId}.',
        );
      } else if (widget.initialPatientUniqueId != null) {
        _currentSelectedPatientUniqueId = widget.initialPatientUniqueId;
        _currentSelectedPatientName = widget.initialPatientName;
        patientNameSearchController.text = "";

        _loadMedicationsForPatient(
          patientUniqueId: _currentSelectedPatientUniqueId!,
          isForDoctorScheduled: true,
        );
        developer.log(
          'MedicationPage: Dipanggil dengan initialPatientUniqueId (untuk Dokter): ${widget.initialPatientUniqueId}.',
        );
      } else {
        _clearPatientSelection();
        developer.log(
          'MedicationPage: Dokter mengakses tanpa pasien terpilih. Memuat obat kosong.',
        );
      }
    } else {
      developer.log(
        'MedicationPage: Data pengguna tidak ditemukan di secure storage. Mengarahkan ke Login.',
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _loadMedicationsForPatient({
    int? patientGlobalId,
    String? patientUniqueId,
    bool isForSelfOrFamily = false,
    bool isForDoctorScheduled = false,
  }) {
    if ((patientGlobalId == null && patientUniqueId == null) ||
        (patientUniqueId != null && patientUniqueId.isEmpty)) {
      _clearMedicationsAndShowMessage();
      return;
    }

    developer.log(
      'MedicationPage: Memuat obat untuk pasien ID Global: $patientGlobalId, ID Unik: $patientUniqueId. Is History: ${widget.isHistory}. Is Patient Role (param): ${widget.isPatientRole}. Is Family Role (param): ${widget.isFamilyRole}. isForSelfOrFamily: $isForSelfOrFamily. isForDoctorScheduled: $isForDoctorScheduled',
    );

    if (widget.isHistory) {
      developer.log(
        'DEBUG_MED_LOAD: Dispatching GetMedicationHistoryRequested',
      );
      if (patientUniqueId != null && patientUniqueId.isNotEmpty) {
        context.read<MedicationBloc>().add(
          GetMedicationHistoryRequested(patientUniqueId: patientUniqueId),
        );
      } else if (patientGlobalId != null) {
        developer.log(
          'MedicationPage: Peringatan: Memuat riwayat dengan Global ID saja. Pastikan backend mendukung.',
        );
        context.read<MedicationBloc>().add(
          GetMedicationHistoryRequested(patientGlobalId: patientGlobalId),
        );
      }
    } else {
      if (isForSelfOrFamily) {
        developer.log(
          'DEBUG_MED_LOAD: Dispatching GetMedicationsRequested (for self/family)',
        );
        context.read<MedicationBloc>().add(
          GetMedicationsRequested(
            patientGlobalId: patientGlobalId,
            patientUniqueId: patientUniqueId,
            isForPatientOrFamilyToday: true,
          ),
        );
      } else if (isForDoctorScheduled &&
          patientUniqueId != null &&
          patientUniqueId.isNotEmpty) {
        developer.log(
          'DEBUG_MED_LOAD: Dispatching GetMedicationsRequested (for doctor scheduled)',
        );
        context.read<MedicationBloc>().add(
          GetMedicationsRequested(
            patientUniqueId: patientUniqueId,
            isForDoctorScheduled: true,
          ),
        );
      } else {
        developer.log(
          'DEBUG_MED_LOAD: No specific medication load condition met.',
        );
        _clearMedicationsAndShowMessage();
      }
    }
  }

  void _clearPatientSelection() {
    setState(() {
      _currentSelectedPatientUniqueId = null;
      _currentSelectedPatientName = null;
      _currentSelectedPatientGlobalId = null;
      _patientSearchResults = [];
      patientNameSearchController.clear();
      developer.log('MedicationPage: Pilihan pasien dibersihkan.');
      _clearMedicationsAndShowMessage();
    });
  }

  void _clearMedicationsAndShowMessage() {
    context.read<MedicationBloc>().add(MedicationClearRequested());
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle =
        widget.isHistory
            ? 'Riwayat Konsumsi Obat'
            : widget.isPatientRole
            ? 'Jadwal Obat Anda'
            : widget.isFamilyRole
            ? 'Obat ${_currentSelectedPatientName ?? 'Pasien'}'
            : 'Manajemen Obat Pasien';

    String dynamicAppBarTitle = appBarTitle;
    if (widget.initialPatientUniqueId != null &&
        _currentSelectedPatientName != null) {
      dynamicAppBarTitle = 'Manajemen Obat ${_currentSelectedPatientName}';
    } else if (widget.initialPatientUniqueId != null &&
        _currentSelectedPatientName == null &&
        _currentUserData?.role?.toLowerCase() == 'dokter') {
      dynamicAppBarTitle =
          'Manajemen Obat ${widget.initialPatientName ?? 'Pasien'}';
    }

    return Scaffold(
      backgroundColor:
          AppColors.lightSheet, // Soft background for the entire page
      appBar: AppBar(
        title: Text(
          dynamicAppBarTitle,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ), // Larger, bolder app bar title
        ),
        backgroundColor: AppColors.deepPurple, // Deep purple app bar
        elevation: 0, // No shadow for a modern flat look
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ), // White icons for contrast
        leading:
            (widget.patientGlobalId != null ||
                        widget.initialPatientUniqueId != null) &&
                    !widget.isPatientRole
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
                : null,
      ),
      body: Column(
        children: [
          if (_currentUserData?.role?.toLowerCase() == 'dokter' &&
              _currentSelectedPatientUniqueId == null &&
              widget.initialPatientUniqueId == null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentSelectedPatientName != null &&
                            _currentSelectedPatientUniqueId != null
                        ? 'Pasien Terpilih: ${_currentSelectedPatientName!} (ID: ${_currentSelectedPatientUniqueId!})'
                        : 'Silakan cari dan pilih pasien untuk mengelola obat.',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepPurple, // Deep purple for emphasis
                    ),
                  ),
                  const SpaceHeight(10),
                  BlocConsumer<PatientBloc, PatientState>(
                    listener: (context, state) {
                      if (state is ConnectedPatientsSearchLoaded) {
                        developer.log(
                          'MedicationPage: ConnectedPatientsSearchLoaded - ${state.searchResults.length} hasil.',
                        );
                        setState(() {
                          _patientSearchResults = state.searchResults;
                        });
                      } else if (state is ConnectedPatientsSearchError) {
                        developer.log(
                          'MedicationPage: ConnectedPatientsSearchError - ${state.message}',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Pencarian Pasien Error: ${state.message}',
                            ),
                          ),
                        );
                        setState(() {
                          _patientSearchResults = [];
                        });
                      } else if (state is PatientLoading) {
                        developer.log(
                          'MedicationPage: PatientBloc is Loading...',
                        );
                      }
                    },
                    builder: (context, state) {
                      bool isLoadingSearch = state is PatientLoading;
                      return Autocomplete<PatientSearchResult>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          developer.log(
                            'MedicationPage: optionsBuilder called with query: ${textEditingValue.text}',
                          );
                          if (textEditingValue.text.isEmpty) {
                            _patientSearchResults = [];
                            _clearPatientSelection();
                            return const Iterable<PatientSearchResult>.empty();
                          }
                          if (textEditingValue.text.length < 2) {
                            return const Iterable<PatientSearchResult>.empty();
                          }
                          context.read<PatientBloc>().add(
                            SearchConnectedPatientsRequested(
                              queryNama: textEditingValue.text,
                            ),
                          );
                          return _patientSearchResults;
                        },
                        displayStringForOption:
                            (PatientSearchResult option) => option.nama,
                        fieldViewBuilder: (
                          BuildContext context,
                          TextEditingController fieldTextEditingController,
                          FocusNode fieldFocusNode,
                          VoidCallback onFieldSubmitted,
                        ) {
                          patientNameSearchController.text =
                              fieldTextEditingController.text;
                          fieldFocusNode.onKey = (
                            FocusNode node,
                            RawKeyEvent event,
                          ) {
                            if (event is RawKeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.enter) {
                              onFieldSubmitted();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          };
                          return TextFormField(
                            controller: fieldTextEditingController,
                            focusNode: fieldFocusNode,
                            decoration: _inputDecoration(
                              'Cari Nama Pasien Terhubung',
                              suffixIcon:
                                  isLoadingSearch
                                      ? const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.deepPurple,
                                                ), // Deep purple loading
                                          ),
                                        ),
                                      )
                                      : (fieldTextEditingController
                                              .text
                                              .isNotEmpty
                                          ? IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              color: AppColors.grey,
                                            ), // Grey clear icon
                                            onPressed: () {
                                              fieldTextEditingController
                                                  .clear();
                                              _clearPatientSelection();
                                            },
                                          )
                                          : null),
                            ),
                          );
                        },
                        optionsViewBuilder: (
                          BuildContext context,
                          AutocompleteOnSelected<PatientSearchResult>
                          onSelected,
                          Iterable<PatientSearchResult> options,
                        ) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0, // Subtle shadow for dropdown
                              borderRadius: BorderRadius.circular(
                                8.0,
                              ), // Slightly rounded corners for dropdown
                              child: SizedBox(
                                height: options.isNotEmpty ? 200.0 : 0.0,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder: (
                                    BuildContext context,
                                    int index,
                                  ) {
                                    final PatientSearchResult option = options
                                        .elementAt(index);
                                    return ListTile(
                                      title: Text(
                                        option.nama,
                                        style: const TextStyle(
                                          color: AppColors.black,
                                        ),
                                      ), // Black text
                                      subtitle: Text(
                                        'ID: ${option.idUnik}',
                                        style: const TextStyle(
                                          color: AppColors.grey,
                                        ),
                                      ), // Grey subtitle
                                      onTap: () {
                                        onSelected(option);
                                        setState(() {
                                          _currentSelectedPatientName =
                                              option.nama;
                                          _currentSelectedPatientUniqueId =
                                              option.idUnik;
                                          _currentSelectedPatientGlobalId =
                                              option.idGlobal;
                                          patientNameSearchController.text =
                                              option.nama;
                                        });
                                        if (_currentSelectedPatientUniqueId !=
                                            null) {
                                          _loadMedicationsForPatient(
                                            patientUniqueId:
                                                _currentSelectedPatientUniqueId!,
                                            isForDoctorScheduled: true,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'ID Unik Pasien tidak tersedia.',
                                              ),
                                            ),
                                          );
                                          _clearPatientSelection();
                                        }
                                        _patientSearchFocusNode.unfocus();
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: BlocConsumer<MedicationBloc, MedicationState>(
              listener: (context, state) {
                if (state is MedicationLoading) {
                  developer.log('MedicationPage: MedicationBloc is Loading...');
                } else if (state is MedicationActionSuccess) {
                  developer.log(
                    'MedicationPage: MedicationActionSuccess: ${state.message}',
                  );
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                  setState(() {
                    _pickedImage =
                        null; // Reset picked image after successful upload
                  });

                  if (widget.isHistory) {
                    _loadMedicationsForPatient(
                      patientGlobalId: _currentSelectedPatientGlobalId,
                      patientUniqueId: _currentSelectedPatientUniqueId,
                    );
                  } else if (_currentUserData?.role?.toLowerCase() ==
                      'pasien') {
                    _loadMedicationsForPatient(
                      patientGlobalId: _currentSelectedPatientGlobalId,
                      patientUniqueId: _currentSelectedPatientUniqueId,
                      isForSelfOrFamily: true,
                    );
                  } else if (_currentUserData?.role?.toLowerCase() ==
                          'dokter' &&
                      _currentSelectedPatientUniqueId != null) {
                    _loadMedicationsForPatient(
                      patientUniqueId: _currentSelectedPatientUniqueId!,
                      isForDoctorScheduled: true,
                    );
                  } else if (_currentUserData?.role?.toLowerCase() ==
                          'keluarga' &&
                      _currentSelectedPatientGlobalId != null) {
                    _loadMedicationsForPatient(
                      patientGlobalId: _currentSelectedPatientGlobalId!,
                      patientUniqueId: _currentSelectedPatientUniqueId,
                      isForSelfOrFamily: true,
                    );
                  } else {
                    _clearMedicationsAndShowMessage();
                  }
                } else if (state is MedicationError) {
                  developer.log(
                    'MedicationPage: MedicationError: ${state.message}',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${state.message}')),
                  );
                }
              },
              builder: (context, state) {
                if (_currentUserData?.role?.toLowerCase() == 'dokter' &&
                    _currentSelectedPatientUniqueId == null &&
                    widget.initialPatientUniqueId == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Pilih pasien dari daftar atau gunakan pencarian untuk mengelola obat.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.grey), // Grey text
                      ),
                    ),
                  );
                }

                if (state is MedicationInitial ||
                    (state is MedicationLoading &&
                        !(state is MedicationActionSuccess))) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.deepPurple,
                      ), // Deep purple loading
                    ),
                  );
                } else if (state is MedicationsLoaded) {
                  return _buildMedicationsListForDoctor(
                    state.medications.cast<Medication>(),
                  );
                } else if (state is MedicationSessionsLoaded) {
                  return _buildMedicationsListForPatient(
                    state.sessions.cast<TodaysMedicationSession>(),
                  );
                } else if (state is MedicationHistoryLoaded) {
                  return _buildMedicationHistoryList(state.history);
                } else if (state is MedicationError) {
                  return Center(
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
                            'Gagal memuat atau memproses obat: ${state.message}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.red,
                            ), // Red error text
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Muat obat untuk pasien ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey), // Grey text
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          ((_currentUserData?.role?.toLowerCase() == 'dokter' &&
                      (_currentSelectedPatientUniqueId != null ||
                          widget.initialPatientUniqueId != null)) &&
                  !widget.isHistory)
              ? FloatingActionButton(
                onPressed: () => _showAddEditMedicationDialog(context),
                child: const Icon(Icons.add),
                backgroundColor: AppColors.deepPurple, // Deep purple FAB
                foregroundColor: AppColors.white, // White FAB icon
              )
              : null,
    );
  }

  // Fungsi untuk menampilkan daftar obat untuk role Dokter
  Widget _buildMedicationsListForDoctor(List<Medication> medications) {
    if (medications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Belum ada obat yang ditambahkan untuk pasien ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey), // Grey text
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final medication = medications[index];
        developer.log(
          '[MedicationPage:_buildMedicationsListForDoctor] Rendering: Name="${medication.medicationName}", Dosage="${medication.dosage}", Schedule="${medication.schedule.displayString}"',
        );

        return Card(
          margin: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 18.0,
          ), // Increased margins
          elevation: 8.0, // Increased elevation for a very prominent look
          shadowColor: AppColors.deepPurple.withOpacity(
            0.3,
          ), // Soft purple shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Very rounded corners
            side: const BorderSide(
              color: AppColors.light,
              width: 0.5,
            ), // Subtle light border
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(
              24.0,
            ), // Even more padding inside list tile
            leading: Container(
              padding: const EdgeInsets.all(
                10.0,
              ), // Padding inside container for icon
              decoration: BoxDecoration(
                color: AppColors.deepPurple.withOpacity(
                  0.15,
                ), // Slightly darker deep purple with opacity
                shape: BoxShape.circle, // Circular shape for icon background
              ),
              child: const Icon(
                Icons.medication_outlined,
                color: AppColors.deepPurple,
                size: 32,
              ), // Larger, deep purple icon
            ),
            title: Text(
              medication.medicationName.isNotEmpty
                  ? medication.medicationName
                  : 'Nama Obat Tidak Diketahui',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.black,
              ), // Larger, bolder title
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8), // More space
                Text(
                  'Dosis: ${medication.dosage.isNotEmpty ? medication.dosage : 'Tidak Diketahui'}',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 15,
                  ), // Slightly larger grey text
                ),
                Text(
                  'Jadwal: ${medication.schedule.displayString.isNotEmpty ? medication.schedule.displayString : 'Tidak Diketahui'}',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 15,
                  ), // Slightly larger grey text
                ),
                if (medication.fullPhotoUrl != null &&
                    medication.fullPhotoUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 16.0,
                    ), // More space above image
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ImageViewerPage(
                                  photoPath: medication.photoUrl!,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        width: 140, // Even larger image thumbnail
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            15,
                          ), // More rounded image corners
                          border: Border.all(
                            color: AppColors.stroke,
                            width: 2.0,
                          ), // Thicker stroke
                          boxShadow: [
                            // Subtle shadow for the image itself
                            BoxShadow(
                              color: AppColors.light.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            medication.fullPhotoUrl!,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.broken_image,
                                  size: 70, // Even larger error icon
                                  color:
                                      AppColors
                                          .light, // Lighter grey for error icon
                                ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.deepPurple,
                                  ), // Deep purple loading
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            trailing:
                _currentUserData?.role?.toLowerCase() == 'dokter' &&
                        !widget.isHistory
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color:
                                AppColors.deepPurple, // Deep purple edit icon
                          ),
                          onPressed: () {
                            _showAddEditMedicationDialog(
                              context,
                              medication: medication,
                            );
                          },
                          tooltip: 'Edit Obat', // Add tooltip for better UX
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: AppColors.redCustom,
                          ), // Use redCustom for delete
                          onPressed: () {
                            _confirmDeleteMedication(context, medication.id);
                          },
                          tooltip: 'Hapus Obat', // Add tooltip
                        ),
                      ],
                    )
                    : null,
          ),
        );
      },
    );
  }

  // Fungsi untuk menampilkan daftar RIWAYAT KONSUMSI secara individual
  Widget _buildMedicationHistoryList(List<MedicationHistoryData> historyItems) {
    if (historyItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Tidak ada riwayat konsumsi obat untuk pasien ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey), // Grey text
          ),
        ),
      );
    }

    // Kelompokkan riwayat berdasarkan medicationId (dan nama obat untuk tampilan)
    final Map<int?, List<MedicationHistoryData>> groupedHistory = groupBy(
      historyItems,
      (item) => item.medicationId, // Group by medication ID
    );

    return ListView.builder(
      itemCount: groupedHistory.keys.length,
      itemBuilder: (context, index) {
        final medicationId = groupedHistory.keys.elementAt(index);
        final historyForThisMedication = groupedHistory[medicationId]!;
        final firstHistoryItem = historyForThisMedication.first;

        return Card(
          margin: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 18.0,
          ), // Increased margins
          elevation: 6.0, // Increased elevation
          shadowColor: AppColors.deepPurple.withOpacity(
            0.3,
          ), // Soft purple shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // More rounded corners
            side: const BorderSide(
              color: AppColors.light,
              width: 0.5,
            ), // Subtle light border
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              8,
            ), // Adjusted padding
            leading: Container(
              padding: const EdgeInsets.all(
                10.0,
              ), // Padding inside container for icon
              decoration: BoxDecoration(
                color: AppColors.deepPurple.withOpacity(
                  0.15,
                ), // Slightly darker deep purple with opacity
                shape: BoxShape.circle, // Circular shape for icon background
              ),
              child: const Icon(
                Icons.history_edu_outlined,
                color: AppColors.deepPurple,
                size: 32,
              ), // Larger deep purple icon
            ),
            title: Text(
              firstHistoryItem.medicationName ?? 'Nama Obat Tidak Diketahui',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ), // Bolder title
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  'Dosis: ${firstHistoryItem.dosage ?? 'Tidak Diketahui'}',
                  style: const TextStyle(color: AppColors.grey, fontSize: 15),
                ), // Grey text
                Text(
                  firstHistoryItem.schedule?.displayString ??
                      'Jadwal: Tidak Diketahui',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 15,
                  ), // Grey text
                ),
                if (firstHistoryItem.fullPhotoUrl != null &&
                    firstHistoryItem.fullPhotoUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ImageViewerPage(
                                  photoPath: firstHistoryItem.fullPhotoUrl!,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        width: 140, // Even larger image thumbnail
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            15,
                          ), // More rounded image corners
                          border: Border.all(
                            color: AppColors.stroke,
                            width: 2.0,
                          ), // Thicker stroke
                          boxShadow: [
                            // Subtle shadow for the image itself
                            BoxShadow(
                              color: AppColors.light.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            firstHistoryItem.fullPhotoUrl!,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.broken_image,
                                  size: 70,
                                  color:
                                      AppColors
                                          .light, // Lighter grey for error icon
                                ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.deepPurple,
                                  ), // Deep purple loading
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            children: <Widget>[
              // Inner list items for individual sessions
              ...historyForThisMedication.map((sessionItem) {
                String formattedConsumptionTime =
                    sessionItem.consumptionTime != null
                        ? DateFormat(
                          'dd MMMM yyyy, HH:mm', // Full date and time format
                        ).format(
                          DateTime.parse(
                            sessionItem.consumptionTime!,
                          ).toLocal(),
                        )
                        : 'Tidak Diketahui';
                developer.log(
                  'DEBUG: sessionItem.medicationName: ${sessionItem.medicationName}',
                );
                developer.log(
                  'DEBUG: sessionItem.scheduledTime: "${sessionItem.scheduledTime}" (length: ${sessionItem.scheduledTime?.length ?? 0}, isNotEmpty: ${sessionItem.scheduledTime?.isNotEmpty})',
                );
                developer.log(
                  'DEBUG: sessionItem.schedule?.times: ${sessionItem.schedule?.times} (length: ${sessionItem.schedule?.times?.length ?? 0})',
                );

                String detailScheduledTime;
                if (sessionItem.scheduledTime != null &&
                    sessionItem.scheduledTime!.trim().isNotEmpty) {
                  detailScheduledTime = sessionItem.scheduledTime!.trim();
                  developer.log(
                    'DEBUG: Menggunakan scheduledTime: $detailScheduledTime',
                  );
                } else if (sessionItem.schedule?.times != null &&
                    sessionItem.schedule!.times!.length == 1 &&
                    sessionItem.schedule!.times!.first.trim().isNotEmpty) {
                  detailScheduledTime =
                      sessionItem.schedule!.times!.first.trim();
                  developer.log(
                    'DEBUG: Menggunakan schedule.times (satu waktu): $detailScheduledTime',
                  );
                } else if (sessionItem.schedule?.times != null &&
                    sessionItem.schedule!.times!.isNotEmpty) {
                  detailScheduledTime = sessionItem.schedule!.times!.join(', ');
                  developer.log(
                    'DEBUG: Menggunakan schedule.times (banyak waktu): $detailScheduledTime',
                  );
                } else {
                  detailScheduledTime = 'Tidak Tersedia';
                  developer.log('DEBUG: Menggunakan "Tidak Tersedia"');
                }

                String statusDisplay =
                    sessionItem.status == 'taken'
                        ? 'Diminum'
                        : sessionItem.status ?? 'Tidak Diketahui';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 10.0,
                  ), // Increased horizontal padding and vertical padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waktu Jadwal: ${detailScheduledTime}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.black,
                        ),
                      ), // Slightly larger black text
                      Text(
                        'Waktu Aktual: ${formattedConsumptionTime}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.black,
                        ),
                      ), // Slightly larger black text
                      Text(
                        'Status: ${statusDisplay}',
                        style: TextStyle(
                          fontSize: 16, // Slightly larger font for status
                          fontWeight: FontWeight.bold,
                          color:
                              statusDisplay == 'Diminum'
                                  ? AppColors.green
                                  : AppColors
                                      .redCustom, // Green/RedCustom for status
                        ),
                      ),
                      if (sessionItem.notes != null &&
                          sessionItem.notes!.isNotEmpty)
                        Text(
                          'Catatan: ${sessionItem.notes}',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColors.grey,
                            fontSize: 14,
                          ),
                        ), // Smaller italic grey text
                      const Divider(
                        height: 20,
                        color: AppColors.stroke,
                      ), // Thicker and taller divider
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Fungsi untuk menampilkan daftar sesi obat untuk role Pasien/Keluarga
  Widget _buildMedicationsListForPatient(
    List<TodaysMedicationSession> sessions,
  ) {
    if (sessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Tidak ada riwayat konsumsi obat untuk pasien ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey), // Grey text
          ),
        ),
      );
    }

    // Kelompokkan sesi berdasarkan obat
    final Map<int, List<TodaysMedicationSession>> groupedSessions = groupBy(
      sessions,
      (session) => session.medicationId,
    );

    return ListView.builder(
      itemCount: groupedSessions.keys.length,
      itemBuilder: (context, index) {
        final medicationId = groupedSessions.keys.elementAt(index);
        final sessionsForThisMedication = groupedSessions[medicationId]!;
        final firstSession = sessionsForThisMedication.first;

        final bool isPrnOrUnknown =
            firstSession.scheduleType == 'as_needed' ||
            firstSession.scheduleType == 'unknown';

        return Card(
          margin: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 18.0,
          ), // Increased margins
          elevation: 6.0, // Increased elevation
          shadowColor: AppColors.deepPurple.withOpacity(
            0.3,
          ), // Soft purple shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Very rounded corners
            side: const BorderSide(
              color: AppColors.light,
              width: 0.5,
            ), // Subtle light border
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              8,
            ), // Adjusted padding
            leading: Container(
              padding: const EdgeInsets.all(
                10.0,
              ), // Padding inside container for icon
              decoration: BoxDecoration(
                color: AppColors.deepPurple.withOpacity(
                  0.15,
                ), // Slightly darker deep purple with opacity
                shape: BoxShape.circle, // Circular shape for icon background
              ),
              child: const Icon(
                Icons.medication_outlined,
                color: AppColors.deepPurple,
                size: 32,
              ), // Larger, deep purple icon
            ),
            title: Text(
              firstSession.medicationName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.black,
              ), // Bolder title
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  'Dosis: ${firstSession.dosage}',
                  style: const TextStyle(color: AppColors.grey, fontSize: 15),
                ), // Grey text
                if (firstSession.description != null &&
                    firstSession.description!.isNotEmpty)
                  Text(
                    'Deskripsi: ${firstSession.description}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 15),
                  ), // Grey text

                if (firstSession.fullPhotoUrl != null &&
                    firstSession.fullPhotoUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        // Send the ORIGINAL photoUrl from the backend to ImageViewerPage.
                        // ImageViewerPage will construct the full URL itself.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ImageViewerPage(
                                  photoPath: firstSession.photoUrl!,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        width: 140, // Even larger image thumbnail
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            15,
                          ), // More rounded image corners
                          border: Border.all(
                            color: AppColors.stroke,
                            width: 2.0,
                          ), // Thicker stroke
                          boxShadow: [
                            // Subtle shadow for the image itself
                            BoxShadow(
                              color: AppColors.light.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            firstSession.fullPhotoUrl!,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.broken_image,
                                  size: 70,
                                  color:
                                      AppColors
                                          .light, // Lighter grey for error icon
                                ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.deepPurple,
                                  ), // Deep purple loading
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            children: <Widget>[
              if (isPrnOrUnknown)
                ListTile(
                  title: const Text(
                    'Sesuai Kebutuhan',
                    style: TextStyle(fontSize: 16, color: AppColors.black),
                  ), // Black text
                  trailing: Checkbox(
                    value: firstSession.isTaken,
                    tristate: false,
                    onChanged: (bool? value) {
                      if (value != null) {
                        context.read<MedicationBloc>().add(
                          MarkMedicationAsTakenRequested(
                            medicationId: firstSession.medicationId,
                            isTaken: value,
                            scheduledTime: null,
                          ),
                        );
                      }
                    },
                    activeColor: AppColors.deepPurple, // Deep purple checkbox
                  ),
                )
              else
                ...sessionsForThisMedication.map((session) {
                  return ListTile(
                    title: Text(
                      '${session.scheduledTime}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.black,
                      ),
                    ), // Black text
                    subtitle: Text(
                      'Status: ${session.status}',
                      style: TextStyle(
                        fontSize: 15, // Slightly larger font for status
                        fontWeight: FontWeight.bold,
                        color:
                            session.status == 'taken'
                                ? AppColors.green
                                : AppColors
                                    .redCustom, // Green/RedCustom for status
                      ),
                    ),
                    trailing: Checkbox(
                      value: session.isTaken,
                      tristate: false,
                      onChanged: (bool? value) {
                        if (value != null) {
                          context.read<MedicationBloc>().add(
                            MarkMedicationAsTakenRequested(
                              medicationId: session.medicationId,
                              isTaken: value,
                              scheduledTime: session.scheduledTime,
                            ),
                          );
                        }
                      },
                      activeColor: AppColors.deepPurple, // Deep purple checkbox
                    ),
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddEditMedicationDialog(
    BuildContext context, {
    Medication? medication,
  }) async {
    final TextEditingController nameController = TextEditingController(
      text: medication?.medicationName ?? '',
    );
    final TextEditingController dosageController = TextEditingController(
      text: medication?.dosage ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: medication?.description ?? '',
    );

    // Ensure all local variables are initialized
    String _dialogSelectedScheduleType;
    int _dialogSelectedDailyFrequency;
    List<TimeOfDay> _dialogSelectedTimes;
    File? _dialogPickedImage;
    String? _dialogExistingPhotoUrl;

    // Initial setup based on whether it's edit or new add mode
    if (medication != null) {
      _dialogSelectedScheduleType = medication.schedule.type;
      _dialogPickedImage =
          null; // Assume no new image selected until user picks one
      _dialogExistingPhotoUrl =
          medication.fullPhotoUrl; // Display old image if available

      developer.log(
        'DEBUG: _showAddEditMedicationDialog: Edit Mode. Medication ID: ${medication.id}. Initial Schedule Type: ${_dialogSelectedScheduleType}. Raw Schedule: ${jsonEncode(medication.schedule.toMap())}',
        name: 'MedicationDialog',
      );

      // Logic to initialize frequency and times for edit mode
      if (_dialogSelectedScheduleType == 'daily_fixed_times' &&
          medication.schedule.times != null) {
        developer.log(
          'DEBUG: Handling daily_fixed_times. Raw times: ${medication.schedule.times}',
          name: 'MedicationDialog',
        );
        _dialogSelectedTimes = []; // Initialize empty
        for (final timeStr in medication.schedule.times!) {
          // Validate time string format and parse with try-catch
          final parts = timeStr.split(':');
          if (parts.length != 2) {
            developer.log(
              'ERROR: Invalid time string format "$timeStr". Expected HH:mm. Skipping this time entry.',
              name: 'MedicationDialog',
            );
            continue; // Continue to the next time entry if format is invalid
          }
          try {
            _dialogSelectedTimes.add(
              TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
            );
            developer.log(
              'DEBUG: Successfully parsed time: $timeStr',
              name: 'MedicationDialog',
            );
          } on FormatException catch (e) {
            developer.log(
              'ERROR: FormatException parsing time "$timeStr": $e. Skipping this time entry.',
              name: 'MedicationDialog',
            );
            continue; // Continue if parsing fails
          } catch (e) {
            // Catch all other unexpected exceptions during parsing
            developer.log(
              'ERROR: Unexpected error parsing time "$timeStr": $e. Skipping this time entry.',
              name: 'MedicationDialog',
            );
            continue;
          }
        }
        _dialogSelectedDailyFrequency = _dialogSelectedTimes.length;
        // Ensure at least 1 time if daily_fixed_times type, even if no valid ones were parsed
        if (_dialogSelectedDailyFrequency == 0) {
          developer.log(
            'WARNING: No valid daily_fixed_times found after parsing. Defaulting to 1x now.',
            name: 'MedicationDialog',
          );
          _dialogSelectedDailyFrequency = 1;
          _dialogSelectedTimes = [TimeOfDay.now()];
        }
      }
      // END of 'daily_fixed_times' block
      // Ensure there are no 'else if' blocks for 'specific_days_of_week' here
      else {
        // This block is for 'as_needed' or 'unknown' schedule type,
        // or if medication.schedule.times is null/empty for daily_fixed_times
        developer.log(
          'DEBUG: Handling as_needed or unknown schedule type, or null/empty times for daily_fixed_times.',
          name: 'MedicationDialog',
        );
        _dialogSelectedDailyFrequency = 1; // Default frequency to 1
        _dialogSelectedTimes = []; // No specific times for PRN/unknown
      }
    } else {
      // Add new mode
      developer.log(
        'DEBUG: _showAddEditMedicationDialog: Add New Medication Mode.',
        name: 'MedicationDialog',
      );
      _dialogSelectedScheduleType = 'daily_fixed_times'; // Initial default
      _dialogSelectedDailyFrequency = 1; // Initial default
      _dialogSelectedTimes = [TimeOfDay.now()]; // Default 1 time
      _dialogPickedImage = null;
      _dialogExistingPhotoUrl = null;
    }
    developer.log(
      'DEBUG: _showAddEditMedicationDialog END of initialization. Final Schedule Type: $_dialogSelectedScheduleType, Frequency: $_dialogSelectedDailyFrequency, Times: $_dialogSelectedTimes',
      name: 'MedicationDialog',
    );

    final _dialogFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          // StatefulBuilder is important to update state inside the dialog
          builder: (BuildContext context, StateSetter setDialogState) {
            Future<void> _pickTimeForDialog(int index) async {
              // Dynamic time correction: receives index
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime:
                    _dialogSelectedTimes.length > index
                        ? _dialogSelectedTimes[index]
                        : TimeOfDay.now(), // Dynamic time correction: Initial time
                builder: (BuildContext context, Widget? child) {
                  // Add builder for TimePicker theme
                  return Theme(
                    data: ThemeData.light().copyWith(
                      primaryColor:
                          AppColors
                              .deepPurple, // Apply custom deep purple color
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.deepPurple,
                      ), // Apply custom deep purple color
                      buttonTheme: const ButtonThemeData(
                        textTheme: ButtonTextTheme.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setDialogState(() {
                  // Dynamic time correction: update time at specific index
                  if (_dialogSelectedTimes.length <= index) {
                    // If list is not long enough (e.g., user deleted all then added again)
                    _dialogSelectedTimes.add(picked);
                  } else {
                    _dialogSelectedTimes[index] = picked;
                  }
                  // Optional: sort if you want times always in order
                  _dialogSelectedTimes.sort(
                    (a, b) =>
                        (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute),
                  );
                });
              }
            }
            // END of Dynamic time correction: _pickTimeForDialog

            // Helper function to format TimeOfDay
            String _formatTimeOfDay(TimeOfDay tod) {
              final now = DateTime.now();
              final dt = DateTime(
                now.year,
                now.month,
                now.day,
                tod.hour,
                tod.minute,
              );
              return DateFormat.Hm().format(dt);
            }

            // Helper function for image selection, updated for StatefulBuilder
            void _showImageSourceSelectionDialogForDialog() {
              showModalBottomSheet(
                context: dialogContext, // Use dialogContext
                builder: (BuildContext bc) {
                  return SafeArea(
                    child: Wrap(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(
                            Icons.photo_library,
                            color: AppColors.deepPurple,
                          ), // Deep purple icon
                          title: const Text(
                            'Pilih dari Galeri',
                            style: TextStyle(color: AppColors.black),
                          ), // Black text
                          onTap: () async {
                            Navigator.of(dialogContext).pop();
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (image != null) {
                              setDialogState(() {
                                _dialogPickedImage = File(image.path);
                                _dialogExistingPhotoUrl =
                                    null; // Clear old URL if new image is selected
                              });
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.camera_alt,
                            color: AppColors.deepPurple,
                          ), // Deep purple icon
                          title: const Text(
                            'Ambil dari Kamera',
                            style: TextStyle(color: AppColors.black),
                          ), // Black text
                          onTap: () async {
                            Navigator.of(dialogContext).pop();
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.camera,
                            );
                            if (image != null) {
                              setDialogState(() {
                                _dialogPickedImage = File(image.path);
                                _dialogExistingPhotoUrl = null;
                              });
                            }
                          },
                        ),
                        if (_dialogPickedImage != null ||
                            _dialogExistingPhotoUrl !=
                                null) // Show delete button only if there's a photo
                          ListTile(
                            // Delete photo button
                            leading: const Icon(
                              Icons.delete_forever,
                              color: AppColors.red, // Red icon
                            ),
                            title: const Text(
                              'Hapus Foto',
                              style: TextStyle(
                                color: AppColors.red,
                              ), // Red text
                            ),
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              setDialogState(() {
                                _dialogPickedImage = null;
                                _dialogExistingPhotoUrl = null;
                              });
                            },
                          ),
                      ],
                    ),
                  );
                },
              );
            }

            return AlertDialog(
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
              title: Text(
                medication == null ? 'Tambah Obat Baru' : 'Edit Obat',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                  fontSize: 22,
                ), // Larger, bolder black title
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _dialogFormKey,
                  child: SizedBox(
                    width:
                        MediaQuery.of(context).size.width *
                        0.85, // Wider dialog for better input visibility
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: _inputDecoration('Nama Obat'),
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Nama obat wajib diisi'
                                      : null,
                        ),
                        const SpaceHeight(16),
                        TextFormField(
                          controller: dosageController,
                          decoration: _inputDecoration('Dosis'),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Dosis wajib diisi' : null,
                        ),
                        const SpaceHeight(16),
                        // Main Frequency Dropdown (Daily, Weekly, PRN)
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration(
                            'Tipe Frekuensi Konsumsi',
                          ),
                          value: _dialogSelectedScheduleType,
                          hint: const Text('Pilih tipe frekuensi'),
                          items: const [
                            DropdownMenuItem(
                              value: 'daily_fixed_times',
                              child: Text(
                                'Harian (Pilih frekuensi)',
                                style: TextStyle(color: AppColors.black),
                              ), // Black text
                            ),
                          ],
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              _dialogSelectedScheduleType = newValue!;
                              if (_dialogSelectedScheduleType ==
                                  'daily_fixed_times') {
                                _dialogSelectedDailyFrequency = 1;
                                _dialogSelectedTimes = [TimeOfDay.now()];
                              } else {
                                _dialogSelectedDailyFrequency = 0;
                                _dialogSelectedTimes = [];
                              }
                            });
                          },
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Tipe frekuensi konsumsi wajib diisi'
                                      : null,
                        ),
                        const SpaceHeight(16),

                        // Daily frequency control (1x, 2x, 3x, 4x)
                        if (_dialogSelectedScheduleType == 'daily_fixed_times')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jumlah Kali Sehari:',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium!.copyWith(
                                  color: AppColors.black,
                                ), // Black text
                              ),
                              DropdownButtonFormField<int>(
                                decoration: _inputDecoration('Jumlah Kali'),
                                value: _dialogSelectedDailyFrequency,
                                items: const [
                                  DropdownMenuItem(
                                    value: 1,
                                    child: Text(
                                      '1x sehari',
                                      style: TextStyle(color: AppColors.black),
                                    ),
                                  ), // Black text
                                  DropdownMenuItem(
                                    value: 2,
                                    child: Text(
                                      '2x sehari',
                                      style: TextStyle(color: AppColors.black),
                                    ),
                                  ), // Black text
                                  DropdownMenuItem(
                                    value: 3,
                                    child: Text(
                                      '3x sehari',
                                      style: TextStyle(color: AppColors.black),
                                    ),
                                  ), // Black text
                                  DropdownMenuItem(
                                    value: 4,
                                    child: Text(
                                      '4x sehari',
                                      style: TextStyle(color: AppColors.black),
                                    ),
                                  ), // Black text
                                ],
                                onChanged: (int? newValue) {
                                  setDialogState(() {
                                    _dialogSelectedDailyFrequency = newValue!;
                                    _dialogSelectedTimes = List.generate(
                                      newValue,
                                      (index) =>
                                          index < _dialogSelectedTimes.length
                                              ? _dialogSelectedTimes[index]
                                              : TimeOfDay.now(),
                                    );
                                  });
                                },
                                validator:
                                    (value) =>
                                        value == null
                                            ? 'Jumlah frekuensi wajib diisi'
                                            : null,
                              ),
                              const SpaceHeight(16),
                            ],
                          ),

                        // Time input (for daily_fixed_times)
                        if (_dialogSelectedScheduleType == 'daily_fixed_times')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih Waktu Konsumsi:',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium!.copyWith(
                                  color: AppColors.black,
                                ), // Black text
                              ),
                              const SpaceHeight(8),
                              ...List.generate(_dialogSelectedDailyFrequency, (
                                index,
                              ) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: InkWell(
                                    onTap: () => _pickTimeForDialog(index),
                                    child: InputDecorator(
                                      decoration: _inputDecoration(
                                        'Waktu ${index + 1}',
                                        suffixIcon: IconButton(
                                          icon: const Icon(
                                            Icons.access_time,
                                            color: AppColors.deepPurple,
                                          ), // Deep purple icon
                                          onPressed:
                                              () => _pickTimeForDialog(index),
                                        ),
                                      ),
                                      baseStyle: Theme.of(
                                        context,
                                      ).textTheme.titleMedium!.copyWith(
                                        color: AppColors.black,
                                      ), // Black text
                                      child: Text(
                                        _formatTimeOfDay(
                                          _dialogSelectedTimes[index],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              if (_dialogSelectedDailyFrequency < 4)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setDialogState(() {
                                      if (_dialogSelectedScheduleType ==
                                              'daily_fixed_times' &&
                                          _dialogSelectedDailyFrequency < 4) {
                                        _dialogSelectedDailyFrequency++;
                                      }
                                      _dialogSelectedTimes.add(TimeOfDay.now());
                                      _dialogSelectedTimes.sort(
                                        (a, b) =>
                                            (a.hour * 60 + a.minute) -
                                            (b.hour * 60 + b.minute),
                                      );
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Tambah Waktu'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors
                                            .deepPurple, // Deep purple button
                                    foregroundColor:
                                        AppColors.white, // White text
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ), // More rounded button
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ), // Add padding
                                  ),
                                ),
                              const SpaceHeight(16),
                            ],
                          ),

                        if (_dialogSelectedScheduleType == 'as_needed')
                          TextFormField(
                            controller: descriptionController,
                            decoration: _inputDecoration('Catatan (opsional)'),
                            maxLines: 3,
                          ),
                        const SpaceHeight(16),
                        // Medication Photo Section
                        GestureDetector(
                          onTap: _showImageSourceSelectionDialogForDialog,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color:
                                  AppColors
                                      .lightSheet, // Light sheet background
                              borderRadius: BorderRadius.circular(
                                16,
                              ), // More rounded corners
                              border: Border.all(
                                color: AppColors.light,
                                width: 1.5,
                              ), // Lighter, slightly thicker border
                            ),
                            child:
                                _dialogPickedImage != null
                                    ? ClipRRect(
                                      // Clip image to container's border radius
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.file(
                                        _dialogPickedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : (_dialogExistingPhotoUrl != null &&
                                            _dialogExistingPhotoUrl!.isNotEmpty
                                        ? ClipRRect(
                                          // Clip image to container's border radius
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          child: Image.network(
                                            _dialogExistingPhotoUrl!,
                                            width: double.infinity,
                                            height: 150,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.broken_image,
                                                      size: 50,
                                                      color: AppColors.grey,
                                                    ), // Grey error icon
                                          ),
                                        )
                                        : const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.camera_alt,
                                              size: 50,
                                              color: AppColors.grey,
                                            ), // Grey camera icon
                                            SizedBox(height: 8),
                                            Text(
                                              'Pilih/Ambil Foto Obat (Opsional)',
                                              style: TextStyle(
                                                color: AppColors.grey,
                                              ), // Grey text
                                            ),
                                          ],
                                        )),
                          ),
                        ),
                        const SpaceHeight(16),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.grey,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ), // Grey text, slightly bolder
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_dialogFormKey.currentState!.validate()) {
                      if ((_dialogSelectedScheduleType ==
                              'daily_fixed_times') &&
                          _dialogSelectedTimes.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Waktu konsumsi wajib diisi untuk frekuensi ini!',
                            ),
                          ),
                        );
                        return;
                      }
                      final String finalScheduleType =
                          _dialogSelectedScheduleType;
                      final List<String>? finalTimes =
                          (_dialogSelectedScheduleType == 'daily_fixed_times')
                              ? _dialogSelectedTimes
                                  .map((e) => _formatTimeOfDay(e))
                                  .toList()
                              : null;
                      final MedicationSchedule newMedicationSchedule =
                          MedicationSchedule(
                            type: finalScheduleType,
                            times: finalTimes,
                            daysOfWeek: null,
                            notes:
                                _instructionsController.text.trim().isEmpty
                                    ? null
                                    : _instructionsController.text.trim(),
                          );
                      if (medication == null) {
                        if (_currentSelectedPatientUniqueId == null ||
                            _currentSelectedPatientUniqueId!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Silakan pilih pasien terlebih dahulu sebelum menambah obat.',
                              ),
                            ),
                          );
                          return;
                        }
                        context.read<MedicationBloc>().add(
                          AddMedicationRequested(
                            patientUniqueId: _currentSelectedPatientUniqueId!,
                            request: AddMedicationRequestModel(
                              medicationName: nameController.text.trim(),
                              dosage: dosageController.text.trim(),
                              schedule: newMedicationSchedule,
                              description:
                                  descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                              photoFile: _dialogPickedImage,
                            ),
                          ),
                        );
                      } else {
                        context.read<MedicationBloc>().add(
                          UpdateMedicationRequested(
                            medicationId: medication.id,
                            request: UpdateMedicationRequestModel(
                              medicationName: nameController.text.trim(),
                              dosage: dosageController.text.trim(),
                              schedule: newMedicationSchedule,
                              description:
                                  descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                              photoFile: _dialogPickedImage,
                              photoUrl: _dialogExistingPhotoUrl,
                            ),
                          ),
                        );
                      }
                      Navigator.pop(dialogContext);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepPurple, // Deep purple button
                    foregroundColor: AppColors.white, // White text
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ), // More rounded button
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ), // Add padding
                  ),
                  child: Text(medication == null ? 'Tambah' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _pickedImage = null;
        });
      }
    });
  }

  Future<void> _confirmDeleteMedication(
    BuildContext context,
    int medicationId,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ), // More rounded dialog corners
            titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 10.0,
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            title: const Text(
              'Konfirmasi Hapus',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.black,
                fontSize: 22,
              ),
            ), // Larger, bolder black title
            content: const Text(
              'Apakah Anda yakin ingin menghapus obat ini?',
              style: TextStyle(color: AppColors.grey, fontSize: 16),
            ), // Slightly larger grey content text
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.grey,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ), // Grey text, slightly bolder
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red, // Red button
                  foregroundColor: AppColors.white, // White text
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ), // More rounded button
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ), // Add padding
                ),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      context.read<MedicationBloc>().add(
        DeleteMedicationRequested(medicationId: medicationId),
      );
    }
  }
}
