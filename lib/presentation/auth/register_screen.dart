import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manajemen_obat/data/models/request/register_request_model.dart';
import 'package:manajemen_obat/presentation/auth/bloc/register/register_bloc.dart';
import 'package:manajemen_obat/core/components/spaces.dart';
import 'package:manajemen_obat/core/core.dart';
import 'package:manajemen_obat/presentation/auth/login_screen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final TextEditingController patientNameController = TextEditingController();
  final TextEditingController patientDobController = TextEditingController();
  final TextEditingController patientGenderController = TextEditingController();
  final TextEditingController patientPhoneController = TextEditingController();
  final TextEditingController patientAddressController =
      TextEditingController();

  final TextEditingController doctorNameController = TextEditingController();
  final TextEditingController doctorSpecializationController =
      TextEditingController();
  final TextEditingController doctorPhoneController = TextEditingController();
  final TextEditingController doctorAddressController = TextEditingController();

  final TextEditingController familyNameController = TextEditingController();
  final TextEditingController familyPhoneController = TextEditingController();
  final TextEditingController familyAddressController = TextEditingController();

  String selectedRole = 'pasien';
  final _formKey = GlobalKey<FormState>();

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
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    patientNameController.dispose();
    patientDobController.dispose();
    patientGenderController.dispose();
    patientPhoneController.dispose();
    patientAddressController.dispose();
    doctorNameController.dispose();
    doctorSpecializationController.dispose();
    doctorPhoneController.dispose();
    doctorAddressController.dispose();
    familyNameController.dispose();
    familyPhoneController.dispose();
    familyAddressController.dispose();
    super.dispose();
  }

  Widget _buildFormField() {
    if (selectedRole == 'pasien') {
      return Column(
        children: [
          TextFormField(
            controller: patientNameController,
            decoration: _inputDecoration('Nama Pasien'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama Pasien tidak boleh kosong';
              }
              return null;
            },
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: patientDobController,
            decoration: _inputDecoration('Tanggal Lahir (YYYY-MM-DD)'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tanggal Lahir tidak boleh kosong';
              }
              return null;
            },
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: patientGenderController,
            decoration: _inputDecoration('Jenis Kelamin'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Jenis Kelamin tidak boleh kosong';
              }
              return null;
            },
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: patientPhoneController,
            decoration: _inputDecoration('Nomor Telepon Pasien'),
            keyboardType: TextInputType.phone,
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: patientAddressController,
            decoration: _inputDecoration('Alamat Pasien'),
          ),
        ],
      );
    } else if (selectedRole == 'keluarga') {
      return Column(
        children: [
          TextFormField(
            controller: familyNameController,
            decoration: _inputDecoration('Nama Keluarga'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama Keluarga tidak boleh kosong';
              }
              return null;
            },
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: familyPhoneController,
            decoration: _inputDecoration('Nomor Telepon Keluarga'),
            keyboardType: TextInputType.phone,
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: familyAddressController,
            decoration: _inputDecoration('Alamat Keluarga'),
          ),
        ],
      );
    } else if (selectedRole == 'dokter') {
      return Column(
        children: [
          TextFormField(
            controller: doctorNameController,
            decoration: _inputDecoration('Nama Dokter'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama Dokter tidak boleh kosong';
              }
              return null;
            },
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: doctorSpecializationController,
            decoration: _inputDecoration('Spesialisasi'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Spesialisasi tidak boleh kosong';
              }
              return null;
            },
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: doctorPhoneController,
            decoration: _inputDecoration('Nomor Telepon Dokter'),
            keyboardType: TextInputType.phone,
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: doctorAddressController,
            decoration: _inputDecoration('Alamat Dokter'),
          ),
        ],
      );
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi Pengguna')),
      body: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterLoading) {
            // loading indicator
          } else if (state is RegisterSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            context.pushAndRemoveUntil(const LoginScreen(), (route) => false);
          } else if (state is RegisterFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          }
        },
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'pasien', child: Text('Pasien')),
                      DropdownMenuItem(
                        value: 'keluarga',
                        child: Text('Keluarga'),
                      ),
                      DropdownMenuItem(value: 'dokter', child: Text('Dokter')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                    decoration: _inputDecoration('Pilih Role').copyWith(
                      labelText: 'Pilih Role',
                      hintText: null,
                    ), //  Dropdown
                  ),
                  const SpaceHeight(10),
                  TextFormField(
                    controller: usernameController,
                    decoration: _inputDecoration('Username'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SpaceHeight(10),
                  TextFormField(
                    controller: passwordController,
                    decoration: _inputDecoration('Password').copyWith(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {});
                        },
                        icon: const Icon(Icons.visibility),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SpaceHeight(10),
                  _buildFormField(),
                  const SpaceHeight(20),
                  BlocBuilder<RegisterBloc, RegisterState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed:
                            state is RegisterLoading
                                ? null
                                : () {
                                  if (_formKey.currentState!.validate()) {
                                    final request = RegisterRequestModel(
                                      username: usernameController.text.trim(),
                                      password: passwordController.text.trim(),
                                      role: selectedRole,
                                      patientName:
                                          selectedRole == 'pasien'
                                              ? patientNameController.text
                                                  .trim()
                                              : null,
                                      patientDob:
                                          selectedRole == 'pasien'
                                              ? patientDobController.text.trim()
                                              : null,
                                      patientGender:
                                          selectedRole == 'pasien'
                                              ? patientGenderController.text
                                                  .trim()
                                              : null,
                                      patientPhone:
                                          selectedRole == 'pasien'
                                              ? patientPhoneController.text
                                                  .trim()
                                              : null,
                                      patientAddress:
                                          selectedRole == 'pasien'
                                              ? patientAddressController.text
                                                  .trim()
                                              : null,

                                      doctorName:
                                          selectedRole == 'dokter'
                                              ? doctorNameController.text.trim()
                                              : null,
                                      doctorSpecialization:
                                          selectedRole == 'dokter'
                                              ? doctorSpecializationController
                                                  .text
                                                  .trim()
                                              : null,
                                      doctorPhone:
                                          selectedRole == 'dokter'
                                              ? doctorPhoneController.text
                                                  .trim()
                                              : null,
                                      doctorAddress:
                                          selectedRole == 'dokter'
                                              ? doctorAddressController.text
                                                  .trim()
                                              : null,

                                      familyName:
                                          selectedRole == 'keluarga'
                                              ? familyNameController.text.trim()
                                              : null,
                                      familyPhone:
                                          selectedRole == 'keluarga'
                                              ? familyPhoneController.text
                                                  .trim()
                                              : null,
                                      familyAddress:
                                          selectedRole == 'keluarga'
                                              ? familyAddressController.text
                                                  .trim()
                                              : null,
                                    );
                                    context.read<RegisterBloc>().add(
                                      RegisterRequested(request: request),
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
                          state is RegisterLoading ? 'Memuat...' : 'Daftar',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
