import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manajemen_obat/data/models/repository/auth_repository.dart';
import 'package:manajemen_obat/data/models/repository/doctor_repository.dart';
import 'package:manajemen_obat/data/models/repository/family_repository.dart';
import 'package:manajemen_obat/data/models/repository/medication_repository.dart';
import 'package:manajemen_obat/data/models/repository/patient_repository.dart';
import 'package:manajemen_obat/presentation/auth/bloc/login/login_bloc.dart';
import 'package:manajemen_obat/presentation/auth/bloc/register/register_bloc.dart';
import 'package:manajemen_obat/presentation/doctor/bloc/doctor_bloc.dart';
import 'package:manajemen_obat/presentation/family/bloc/family_bloc.dart';
import 'package:manajemen_obat/presentation/medication/bloc/medication_bloc.dart';
import 'package:manajemen_obat/presentation/camera/bloc/camera_bloc.dart';
import 'package:manajemen_obat/presentation/pasien/bloc/patient_bloc.dart';
import 'package:manajemen_obat/presentation/auth/login_screen.dart';
import 'package:manajemen_obat/presentation/patient_location/bloc/patient_location_bloc.dart';
import 'package:manajemen_obat/service/service_http_client.dart';
import 'package:provider/provider.dart';

void main() {
  final service = ServiceHttpClient();

  final authRepository = AuthRepository(service);
  final patientRepository = PatientRepository(service);
  final medicationRepository = MedicationRepository(service);
  final familyRepository = FamilyRepository(service);
  final doctorRepository = DoctorRepository(service);

  runApp(
    MultiBlocProvider(
      providers: [
        // Provide PatientRepository directly
        Provider<PatientRepository>(
          create: (_) => patientRepository, // Use the already created instance
        ),

        BlocProvider(create: (_) => LoginBloc(authRepository: authRepository)),
        BlocProvider(
          create: (_) => RegisterBloc(authRepository: authRepository),
        ),
        BlocProvider(
          create: (_) => PatientBloc(patientRepository: patientRepository),
        ),
        BlocProvider(
          create:
              (_) => MedicationBloc(medicationRepository: medicationRepository),
        ),
        BlocProvider(
          create: (_) => FamilyBloc(familyRepository: familyRepository),
        ),
        BlocProvider(
          create:
              (context) => PatientLocationBloc(
                patientRepository:
                    patientRepository, // PasienRepository dari variabel lokal
                familyRepository:
                    familyRepository, // FamilyRepository dari variabel lokal
              ),
        ),
        BlocProvider(
          create:
              (_) => DoctorBloc(
                doctorRepository: doctorRepository,
                medicationRepository: medicationRepository,
              ),
        ),
        BlocProvider(create: (_) => CameraBloc()),
      ],
      child: const MyAppContent(),
    ),
  );
}

class MyAppContent extends StatelessWidget {
  const MyAppContent({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asisten Manajemen Obat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
    );
  }
}
