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
      body: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SpaceHeight(170),
                Text(
                  'SELAMAT DATANG ',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SpaceHeight(30),
                TextFormField(
                  controller: usernameController,
                  decoration: _inputDecoration(
                    'Username',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.person),
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
                  controller: passwordController,
                  decoration: _inputDecoration(
                    'Password',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.lock),
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
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
                        style: const TextStyle(color: AppColors.primary),
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
