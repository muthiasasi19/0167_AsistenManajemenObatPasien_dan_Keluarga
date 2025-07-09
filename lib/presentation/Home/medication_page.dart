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
}
