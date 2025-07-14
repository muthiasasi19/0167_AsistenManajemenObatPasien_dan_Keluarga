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

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final GlobalKey<FormState> _key;
  bool isShowPassword = false;

  // Helper method untuk styling InputDecoration
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
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    _key = GlobalKey<FormState>();
    super.initState();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.lightSheet, // Set background color for consistency
      body: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SpaceHeight(100), // Adjusted top space
                Text(
                  'SELAMAT DATANG',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.06,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPurple,
                  ),
                ),
                const SpaceHeight(20),
                //  Tempat Logo/Gambar ---
                Container(
                  width:
                      MediaQuery.of(context).size.width *
                      0.4, // Ukuran logo/gambar
                  height:
                      MediaQuery.of(context).size.width *
                      0.4, // Ukuran logo/gambar
                  decoration: BoxDecoration(
                    color: AppColors.deepPurple.withOpacity(
                      0.1,
                    ), // Latar belakang transparan ungu
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.deepPurple,
                      width: 2,
                    ), // Border ungu
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepPurple.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.medical_services_outlined, //  ikon logo
                      size:
                          MediaQuery.of(context).size.width *
                          0.25, // Ukuran ikon logo
                      color: AppColors.deepPurple, // Warna ikon logo
                    ),
                  ),
                ),
                const SpaceHeight(40), // Space after logo

                TextFormField(
                  controller: usernameController,
                  decoration: _inputDecoration(
                    'Username',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.person, color: AppColors.grey),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SpaceHeight(25),
                TextFormField(
                  // Menggunakan TextFormField langsung
                  controller: passwordController,
                  decoration: _inputDecoration(
                    'Password',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.lock, color: AppColors.grey),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isShowPassword = !isShowPassword;
                        });
                      },
                      icon: Icon(
                        isShowPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                  obscureText: !isShowPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SpaceHeight(30),
                BlocConsumer<LoginBloc, LoginState>(
                  listener: (context, state) {
                    if (state is LoginFailure) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(state.error)));
                    } else if (state is LoginSuccess) {
                      final role =
                          state.responseModel.user?.role?.toLowerCase();

                      if (role == 'dokter') {
                        context.pushAndRemoveUntil(
                          const DokterHomeScreen(),
                          (route) => false,
                        );
                      } else if (role == 'pasien') {
                        context.pushAndRemoveUntil(
                          const PasienHomeScreen(),
                          (route) => false,
                        );
                      } else if (role == 'keluarga') {
                        context.pushAndRemoveUntil(
                          const KeluargaHomeScreen(),
                          (route) => false,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Role tidak dikenali')),
                        );
                      }
                    }
                  },
                  builder: (context, state) {
                    return ElevatedButton(
                      // Menggunakan ElevatedButton
                      onPressed:
                          state is LoginLoading
                              ? null
                              : () {
                                if (_key.currentState!.validate()) {
                                  final request = LoginRequestModel(
                                    username: usernameController.text.trim(),
                                    password: passwordController.text.trim(),
                                  );
                                  context.read<LoginBloc>().add(
                                    LoginRequested(requestModel: request),
                                  );
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: AppColors.deepPurple,
                        foregroundColor: AppColors.white, // White text
                      ),
                      child: Text(
                        state is LoginLoading ? 'Memuat...' : 'Masuk',
                      ),
                    );
                  },
                ),
                const SpaceHeight(20),
                Text.rich(
                  TextSpan(
                    text: 'Belum memiliki akun? Silahkan ',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: MediaQuery.of(context).size.width * 0.03,
                    ),
                    children: [
                      TextSpan(
                        text: 'Daftar disini!',
                        style: const TextStyle(
                          color: AppColors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                context.push(const RegisterPage());
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
