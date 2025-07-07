import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manajemen_obat/presentation/auth/login_screen.dart';
import 'package:manajemen_obat/presentation/Home/medication_page.dart';
import 'package:manajemen_obat/presentation/profil/pasien_profil_screen.dart';
import 'package:manajemen_obat/data/models/response/doctor_response_model.dart';
import 'package:manajemen_obat/data/models/response/login_response_model.dart';
import 'package:manajemen_obat/presentation/pasien/bloc/patient_bloc.dart';

class PasienHomeScreen extends StatefulWidget {
  const PasienHomeScreen({super.key});

  @override
  State<PasienHomeScreen> createState() => _PasienHomeScreenState();
}
