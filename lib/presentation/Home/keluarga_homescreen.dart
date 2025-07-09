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
