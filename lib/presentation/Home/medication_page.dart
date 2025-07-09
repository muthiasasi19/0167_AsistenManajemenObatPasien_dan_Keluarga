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
import 'package:manajemen_obat/presentation/pasien/bloc/patient_bloc.dart';
import 'package:manajemen_obat/presentation/medication/bloc/medication_bloc.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
}
