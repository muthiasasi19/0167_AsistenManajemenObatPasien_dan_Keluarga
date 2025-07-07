import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import ini untuk MultiBlocProvider dan BlocProvider

import 'package:manajemen_obat/main.dart'; // Import main.dart untuk MyAppContent
import 'package:manajemen_obat/service/service_http_client.dart'; // Import ServiceHttpClient
import 'package:manajemen_obat/data/models/repository/auth_repository.dart'; // Import AuthRepository
import 'package:manajemen_obat/data/models/repository/patient_repository.dart'; // Import PatientRepository
import 'package:manajemen_obat/presentation/auth/bloc/login/login_bloc.dart'; // Import LoginBloc
import 'package:manajemen_obat/presentation/auth/bloc/register/register_bloc.dart'; // Import RegisterBloc
import 'package:manajemen_obat/presentation/pasien/bloc/patient_bloc.dart'; // Import PatientBloc

void main() {
  // Anda perlu menginisialisasi dependencies yang sama seperti di main.dart untuk tes
  // Meskipun ini adalah "smoke test", untuk aplikasi yang bergantung pada providers,
  // test harus menyediakan providers tersebut.
  final serviceForTest = ServiceHttpClient();
  final authRepositoryForTest = AuthRepository(serviceForTest);
  final patientRepositoryForTest = PatientRepository(serviceForTest);

  testWidgets('Login Screen Smoke Test', (WidgetTester tester) async {
    // Bangun widget tree yang mirip dengan main.dart untuk menyediakan BLoC
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => LoginBloc(authRepository: authRepositoryForTest),
          ),
          BlocProvider(
            create: (_) => RegisterBloc(authRepository: authRepositoryForTest),
          ),
          BlocProvider(
            create:
                (_) => PatientBloc(patientRepository: patientRepositoryForTest),
          ),
        ],
        child:
            const MyAppContent(), // Menggunakan MyAppContent yang sudah ada di main.dart
      ),
    );

    // Verifikasi bahwa widget di halaman login muncul (contoh: teks 'SELAMAT DATANG KEMBALI')
    expect(find.text('SELAMAT DATANG KEMBALI'), findsOneWidget);

    // Contoh verifikasi lain, misalnya menemukan field username dan password
    expect(
      find.byType(TextFormField),
      findsNWidgets(2),
    ); // Ada 2 TextFormField: Username & Password
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget); // Tombol "Masuk"
  });

  // Anda bisa menambahkan tes widget lainnya di sini jika diperlukan
}
