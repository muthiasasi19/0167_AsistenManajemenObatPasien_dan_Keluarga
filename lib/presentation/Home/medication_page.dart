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

  String? _selectedFrequencyType;
  List<TimeOfDay> _selectedTimes = [];
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
      appBar: AppBar(
        title: Text(dynamicAppBarTitle),
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
                                          ),
                                        ),
                                      )
                                      : (fieldTextEditingController
                                              .text
                                              .isNotEmpty
                                          ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              fieldTextEditingController
                                                  .clear();
                                              _clearPatientSelection();
                                            },
                                          )
                                          : null),
                            ),
                            onFieldSubmitted: (value) {
                              developer.log(
                                'MedicationPage: onFieldSubmitted with value: $value',
                              );
                              final PatientSearchResult? selectedOption =
                                  _patientSearchResults.firstWhereOrNull(
                                    (element) =>
                                        element.nama.toLowerCase() ==
                                        value.toLowerCase(),
                                  );
                              if (selectedOption != null) {
                                developer.log(
                                  'MedicationPage: Pasien dipilih dari hasil pencarian: ${selectedOption.nama}',
                                );
                                setState(() {
                                  _currentSelectedPatientName =
                                      selectedOption.nama;
                                  _currentSelectedPatientUniqueId =
                                      selectedOption.idUnik;
                                  _currentSelectedPatientGlobalId =
                                      selectedOption.idGlobal;
                                  patientNameSearchController.text =
                                      selectedOption.nama;
                                });
                                if (_currentSelectedPatientUniqueId != null) {
                                  _loadMedicationsForPatient(
                                    patientUniqueId:
                                        _currentSelectedPatientUniqueId!,
                                    isForDoctorScheduled: true,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'ID Unik Pasien tidak tersedia.',
                                      ),
                                    ),
                                  );
                                  _clearPatientSelection();
                                }
                                _patientSearchFocusNode.unfocus();
                              } else {
                                developer.log(
                                  'MedicationPage: Tidak ada pasien yang cocok di hasil pencarian atau tidak dipilih dari daftar.',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Pilih pasien dari daftar saran atau periksa nama.',
                                    ),
                                  ),
                                );
                                _clearPatientSelection();
                              }
                            },
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
                              elevation: 4.0,
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
                                      title: Text(option.nama),
                                      subtitle: Text('ID: ${option.idUnik}'),
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
                    child: Text(
                      'Pilih pasien dari daftar atau gunakan pencarian untuk mengelola obat.',
                    ),
                  );
                }

                if (state is MedicationInitial ||
                    (state is MedicationLoading &&
                        !(state is MedicationActionSuccess))) {
                  return const Center(child: CircularProgressIndicator());
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
                    child: Text(
                      'Gagal memuat atau memproses obat: ${state.message}',
                    ),
                  );
                }
                return const Center(child: Text('Muat obat untuk pasien ini.'));
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
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              )
              : null,
    );
  }

  // Fungsi untuk menampilkan daftar obat untuk role Dokter
  Widget _buildMedicationsListForDoctor(List<Medication> medications) {
    if (medications.isEmpty) {
      return const Center(
        child: Text('Belum ada obat yang ditambahkan untuk pasien ini.'),
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
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 2.0,
          child: ListTile(
            title: Text(
              medication.medicationName.isNotEmpty
                  ? medication.medicationName
                  : 'Nama Obat Tidak Diketahui',
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dosis: ${medication.dosage.isNotEmpty ? medication.dosage : 'Tidak Diketahui'}',
                ),
                Text(
                  'Jadwal: ${medication.schedule.displayString.isNotEmpty ? medication.schedule.displayString : 'Tidak Diketahui'}',
                ),

                if (medication.fullPhotoUrl != null &&
                    medication.fullPhotoUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ImageViewerPage(
                                  // Kirim photoUrl ASLI ke ImageViewerPage,
                                  // ImageViewerPage akan membentuk URL lengkapnya sendiri
                                  photoPath: medication.photoUrl!,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        // ... (styling container)
                        child: ClipRRect(
                          // ... (styling ClipRRect)
                          child: Image.network(
                            medication.fullPhotoUrl!, // <--- INI PERUBAHANNYA!
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
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
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                // -------------------------------------------------------------------------------------------------------
              ],
            ),
            // ... (trailing icons)
          ),
        );
      },
    );
  }

  //  Fungsi  untuk menampilkan daftar RIWAYAT KONSUMSI secara individual
  Widget _buildMedicationHistoryList(List<MedicationHistoryData> historyItems) {
    if (historyItems.isEmpty) {
      return const Center(
        child: Text('Tidak ada riwayat konsumsi obat untuk pasien ini.'),
      );
    }

    //  Kelompokkan riwayat berdasarkan medicationId (dan nama obat untuk tampilan)
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
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 2.0,
          child: ExpansionTile(
            title: Text(
              firstHistoryItem.medicationName ?? 'Nama Obat Tidak Diketahui',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dosis: ${firstHistoryItem.dosage ?? 'Tidak Diketahui'}'),
                Text(
                  firstHistoryItem.schedule?.displayString ??
                      'Jadwal: Tidak Diketahui',
                ),
              ],
            ),
            children: <Widget>[
              ...historyForThisMedication.map((sessionItem) {
                String formattedConsumptionTime =
                    sessionItem.consumptionTime != null
                        ? DateFormat(
                          'dd MMMM, HH:mm', // Format tanggal dan waktu
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
                // Jika scheduledTime spesifik tersedia dan tidak kosong, gunakan itu
                if (sessionItem.scheduledTime != null &&
                    sessionItem.scheduledTime!.trim().isNotEmpty) {
                  detailScheduledTime = sessionItem.scheduledTime!.trim();
                  developer.log(
                    'DEBUG: Menggunakan scheduledTime: $detailScheduledTime',
                  );
                }
                // Jika scheduledTime tidak tersedia/kosong TAPI ada times di schedule dan hanya ada SATU waktu, gunakan itu
                else if (sessionItem.schedule?.times != null &&
                    sessionItem.schedule!.times!.length == 1 &&
                    sessionItem.schedule!.times!.first.trim().isNotEmpty) {
                  detailScheduledTime =
                      sessionItem.schedule!.times!.first.trim();
                  developer.log(
                    'DEBUG: Menggunakan schedule.times (satu waktu): $detailScheduledTime',
                  );
                }
                // Jika ada banyak waktu di schedule atau scheduledTime tidak spesifik, tampilkan semua (fallback)
                else if (sessionItem.schedule?.times != null &&
                    sessionItem.schedule!.times!.isNotEmpty) {
                  detailScheduledTime = sessionItem.schedule!.times!.join(', ');
                  developer.log(
                    'DEBUG: Menggunakan schedule.times (banyak waktu): $detailScheduledTime',
                  );
                }
                // Jika tidak ada informasi waktu jadwal sama sekali
                else {
                  detailScheduledTime = 'Tidak Tersedia';
                  developer.log('DEBUG: Menggunakan "Tidak Tersedia"');
                }

                String statusDisplay =
                    sessionItem.status == 'taken'
                        ? 'Diminum'
                        : sessionItem.status ?? 'Tidak Diketahui';

                String sessionDetails = 'Status: $statusDisplay';
                sessionDetails += '\nWaktu Jadwal: $detailScheduledTime';

                if (sessionItem.notes != null &&
                    sessionItem.notes!.isNotEmpty) {
                  sessionDetails += '\nCatatan: ${sessionItem.notes}';
                }
                sessionDetails += '\nWaktu Aktual: $formattedConsumptionTime';

                return ListTile(title: Text(sessionDetails));
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
      return Center(
        child: Text(
          widget.isHistory
              ? 'Tidak ada riwayat konsumsi obat untuk pasien ini.'
              : 'Tidak ada jadwal obat untuk hari ini.',
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
            firstSession.scheduledTime == null ||
            firstSession.scheduleType == 'as_needed' ||
            firstSession.scheduleType == 'unknown';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 2.0,
          child: ExpansionTile(
            title: Text(firstSession.medicationName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dosis: ${firstSession.dosage}'),
                if (firstSession.description != null &&
                    firstSession.description!.isNotEmpty)
                  Text('Deskripsi: ${firstSession.description}'),

                if (firstSession.fullPhotoUrl != null &&
                    firstSession.fullPhotoUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        // Kirim photoUrl ASLI dari backend ke ImageViewerPage.
                        // ImageViewerPage akan membentuk URL lengkapnya sendiri.
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
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            firstSession.fullPhotoUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
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
                  title: const Text('Sesuai Kebutuhan'),
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
                  ),
                )
              else
                ...sessionsForThisMedication.map((session) {
                  return ListTile(
                    title: Text('${session.scheduledTime}'),
                    subtitle: Text('Status: ${session.status}'),
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
      text: medication?.medicationName,
    );
    final TextEditingController dosageController = TextEditingController(
      text: medication?.dosage,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: medication?.description,
    );
    _pickedImage = null;

    // Inisialisasi state dialog untuk edit mode
    if (medication != null) {
      if (medication.schedule.type == 'daily_fixed_times') {
        if (medication.schedule.times?.length == 1) {
          _selectedFrequencyType = 'daily_fixed_times_1';
        } else if (medication.schedule.times?.length == 2) {
          _selectedFrequencyType = 'daily_fixed_times_2';
        } else if (medication.schedule.times?.length == 3) {
          _selectedFrequencyType = 'daily_fixed_times_3';
        } else if (medication.schedule.times?.length == 4) {
          _selectedFrequencyType = 'daily_fixed_times_4';
        } else {
          _selectedFrequencyType = 'daily_fixed_times_1';
        }
      } else {
        _selectedFrequencyType = medication.schedule.type;
      }
      _selectedTimes =
          medication.schedule.times?.map((timeStr) {
            final parts = timeStr.split(':');
            return TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }).toList() ??
          [];
      _instructionsController.text = medication.schedule.notes ?? '';
    } else {
      _selectedFrequencyType = null;
      _selectedTimes = [];
      _instructionsController.clear();
      _pickedImage = null;
    }

    final _dialogFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            Future<void> _pickTime() async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                setDialogState(() {
                  if (!_selectedTimes.contains(picked)) {
                    _selectedTimes.add(picked);
                    _selectedTimes.sort(
                      (a, b) =>
                          (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute),
                    );
                  }
                });
              }
            }

            // Fungsi untuk membuat string TimeOfDay
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

            // Fungsi helper untuk memilih gambar, diperbarui untuk StatefulBuilder
            void _showImageSourceSelectionDialogForDialog() {
              showModalBottomSheet(
                context: dialogContext,
                builder: (BuildContext bc) {
                  return SafeArea(
                    child: Wrap(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Pilih dari Galeri'),
                          onTap: () async {
                            Navigator.of(dialogContext).pop();
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (image != null) {
                              setDialogState(() {
                                _pickedImage = File(image.path);
                              });
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Ambil dari Kamera'),
                          onTap: () async {
                            Navigator.of(dialogContext).pop();
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.camera,
                            );
                            if (image != null) {
                              setDialogState(() {
                                _pickedImage = File(image.path);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            return AlertDialog(
              title: Text(
                medication == null ? 'Tambah Obat Baru' : 'Edit Obat',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _dialogFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: _inputDecoration('Nama Obat'),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Nama obat wajib diisi' : null,
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
                      // Dropdown
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Frekuensi Konsumsi'),
                        value: _selectedFrequencyType,
                        hint: const Text('Pilih frekuensi'),
                        items: const [
                          DropdownMenuItem(
                            value: 'daily_fixed_times_1',
                            child: Text('1x sehari'),
                          ),
                          DropdownMenuItem(
                            value: 'daily_fixed_times_2',
                            child: Text('2x sehari'),
                          ),
                          DropdownMenuItem(
                            value: 'daily_fixed_times_3',
                            child: Text('3x sehari'),
                          ),
                          DropdownMenuItem(
                            value: 'daily_fixed_times_4',
                            child: Text('4x sehari'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setDialogState(() {
                            _selectedFrequencyType = newValue;
                            _selectedTimes = [];
                            _instructionsController.clear();
                          });
                        },
                        validator:
                            (value) =>
                                value == null
                                    ? 'Frekuensi konsumsi wajib diisi'
                                    : null,
                      ),
                      const SpaceHeight(16),

                      if (_selectedFrequencyType != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilih Waktu Konsumsi:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SpaceHeight(8),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children:
                                  _selectedTimes.map((time) {
                                    return Chip(
                                      label: Text(_formatTimeOfDay(time)),
                                      onDeleted: () {
                                        setDialogState(() {
                                          _selectedTimes.remove(time);
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),
                            const SpaceHeight(8),
                            ElevatedButton.icon(
                              onPressed: _pickTime,
                              icon: const Icon(Icons.access_time),
                              label: const Text('Tambah Waktu'),
                            ),
                            const SpaceHeight(16),
                          ],
                        ),

                      TextFormField(
                        controller: descriptionController,
                        decoration: _inputDecoration('Deskripsi (Opsional)'),
                        maxLines: 3,
                      ),
                      const SpaceHeight(16),
                      GestureDetector(
                        onTap: _showImageSourceSelectionDialogForDialog,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child:
                              _pickedImage != null
                                  ? Image.file(_pickedImage!, fit: BoxFit.cover)
                                  : (medication?.fullPhotoUrl != null &&
                                          medication!.fullPhotoUrl!.isNotEmpty
                                      ? Image.network(
                                        medication
                                            .fullPhotoUrl!, // <--- INI PENTING! GUNAKAN fullPhotoUrl!
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                      )
                                      : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.camera_alt,
                                            size: 50,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Pilih/Ambil Foto Obat (Opsional)',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
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
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    setDialogState(() {
                      _pickedImage = null;
                    });
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_dialogFormKey.currentState!.validate()) {
                      if (_selectedFrequencyType != null &&
                          _selectedFrequencyType!.startsWith(
                            'daily_fixed_times_',
                          ) &&
                          _selectedTimes.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Waktu konsumsi wajib diisi untuk frekuensi ini!',
                            ),
                          ),
                        );
                        return;
                      }

                      // Konstruksi objek MedicationSchedule
                      final String finalScheduleType;
                      if (_selectedFrequencyType != null &&
                          _selectedFrequencyType!.startsWith(
                            'daily_fixed_times_',
                          )) {
                        finalScheduleType = 'daily_fixed_times';
                      } else {
                        finalScheduleType = _selectedFrequencyType!;
                      }

                      final MedicationSchedule newMedicationSchedule =
                          MedicationSchedule(
                            type: finalScheduleType,
                            times:
                                _selectedTimes
                                    .map((e) => _formatTimeOfDay(e))
                                    .toList(),
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
                              photoFile: _pickedImage,
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
                              // photoFile: _pickedImage, // Mengirim File jika dipilih
                              photoUrl: medication.photoUrl,
                            ),
                          ),
                        );
                      }
                      Navigator.pop(dialogContext);
                    }
                  },
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
            title: const Text('Konfirmasi Hapus'),
            content: const Text('Apakah Anda yakin ingin menghapus obat ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.white),
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
