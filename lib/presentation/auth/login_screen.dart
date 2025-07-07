import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manajemen_obat/data/models/request/login_request_model.dart';
import 'package:manajemen_obat/presentation/Home/keluarga_homescreen.dart';
import 'package:manajemen_obat/presentation/Home/pasien_homescreen.dart';
import 'package:manajemen_obat/presentation/auth/bloc/login/login_bloc.dart';
import 'package:manajemen_obat/presentation/auth/register_screen.dart';
import 'package:manajemen_obat/core/components/spaces.dart';
import 'package:manajemen_obat/core/core.dart';
import 'package:manajemen_obat/presentation/Home/dokter_homescreen.dart';
import 'package:flutter/gestures.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
