import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manajemen_obat/data/models/request/register_request_model.dart';
import 'package:manajemen_obat/presentation/auth/bloc/register/register_bloc.dart';
import 'package:manajemen_obat/core/components/spaces.dart'; // Tetap gunakan SpaceHeight
import 'package:manajemen_obat/core/core.dart'; // Untuk AppColors dan context.push
import 'package:manajemen_obat/presentation/auth/login_screen.dart'; // Untuk navigasi kembali

// Opsional: Jika Anda masih ingin menggunakan Button.filled dari file components.dart
// import 'package:manajemen_obat/core/components/components.dart';

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
  bool _obscureText = true;

  // Gaya InputDecoration yang akan digunakan berulang untuk TextFormField
  InputDecoration _inputDecoration(
    String labelText, {
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        color: AppColors.grey,
      ), // Consistent grey label
      floatingLabelStyle: const TextStyle(
        color: AppColors.deepPurple,
        fontWeight: FontWeight.bold,
      ), // Bold and purple when floating
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0), // Consistent rounded corners
        borderSide: const BorderSide(
          color: AppColors.light,
        ), // Lighter grey border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(
          color: AppColors.light,
        ), // Lighter grey border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(
          color: AppColors.deepPurple, // Deep purple border when focused
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(
          color: AppColors.red,
        ), // Red border for errors
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.red, width: 2.0),
      ),
      filled: true,
      fillColor: AppColors.white, // White fill
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

  // Helper method to build dynamic form fields based on selected role
  Widget _buildFormField() {
    if (selectedRole == 'pasien') {
      return Column(
        children: [
          TextFormField(
            controller: patientNameController,
            decoration: _inputDecoration(
              'Nama Pasien',
              prefixIcon: const Icon(Icons.person, color: AppColors.grey),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama Pasien tidak boleh kosong';
              }
              return null;
            },
            onChanged: (value) {
              // Trigger validasi ulang saat teks berubah
              if (_formKey.currentState != null &&
                  !_formKey.currentState!.validate()) {
                setState(() {}); // Memaksa rebuild untuk menghapus error
              }
            },
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: patientDobController,
            decoration: _inputDecoration(
              'Tanggal Lahir (YYYY-MM-DD)',
              prefixIcon: const Icon(
                Icons.calendar_today,
                color: AppColors.grey,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tanggal Lahir tidak boleh kosong';
              }
              return null;
            },
            onChanged: (value) {
              if (_formKey.currentState != null &&
                  !_formKey.currentState!.validate()) {
                setState(() {});
              }
            },
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: patientGenderController,
            decoration: _inputDecoration(
              'Jenis Kelamin',
              prefixIcon: const Icon(Icons.wc, color: AppColors.grey),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Jenis Kelamin tidak boleh kosong';
              }
              return null;
            },
            onChanged: (value) {
              if (_formKey.currentState != null &&
                  !_formKey.currentState!.validate()) {
                setState(() {});
              }
            },
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: patientPhoneController,
            decoration: _inputDecoration(
              'Nomor Telepon Pasien',
              prefixIcon: const Icon(Icons.phone, color: AppColors.grey),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nomor Telepon Pasien tidak boleh kosong';
              }
              return null;
            },
            onChanged: (value) {
              if (_formKey.currentState != null &&
                  !_formKey.currentState!.validate()) {
                setState(() {});
              }
            },
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: patientAddressController,
            decoration: _inputDecoration(
              'Alamat Pasien',
              prefixIcon: const Icon(Icons.location_on, color: AppColors.grey),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Alamat Pasien tidak boleh kosong';
              }
              return null;
            },
            onChanged: (value) {
              if (_formKey.currentState != null &&
                  !_formKey.currentState!.validate()) {
                setState(() {});
              }
            },
          ),
        ],
      );
    } else if (selectedRole == 'keluarga') {
      return Column(
        children: [
          TextFormField(
            controller: familyNameController,
            decoration: _inputDecoration(
              'Nama Keluarga',
              prefixIcon: const Icon(Icons.group, color: AppColors.grey),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama Keluarga tidak boleh kosong';
              }
              return null;
            },
            onChanged: (value) {
              if (_formKey.currentState != null &&
                  !_formKey.currentState!.validate()) {
                setState(() {});
              }
            },
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: familyPhoneController,
            decoration: _inputDecoration(
              'Nomor Telepon Keluarga',
              prefixIcon: const Icon(Icons.phone, color: AppColors.grey),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nomor Telepon Keluarga tidak boleh kosong';
              }
              return null;
            },
            onChanged: (value) {
              if (_formKey.currentState != null &&
                  !_formKey.currentState!.validate()) {
                setState(() {});
              }
            },
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: familyAddressController,
            decoration: _inputDecoration(
              'Alamat Keluarga',
              prefixIcon: const Icon(Icons.location_on, color: AppColors.grey),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Alamat Keluarga tidak boleh kosong';
              }
              return null;
            },
            onChanged: (value) {
              if (_formKey.currentState != null &&
                  !_formKey.currentState!.validate()) {
                setState(() {});
              }
            },
          ),
        ],
      );
    } else if (selectedRole == 'dokter') {
      return Column(
        children: [
          TextFormField(
            controller: doctorNameController,
            decoration: _inputDecoration(
              'Nama Dokter',
              prefixIcon: const Icon(
                Icons.medical_services,
                color: AppColors.grey,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama Dokter tidak boleh kosong';
              }
              return null;
            },
            onChanged: (value) {
              if (_formKey.currentState != null &&
                  !_formKey.currentState!.validate()) {
                setState(() {});
              }
            },
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: doctorSpecializationController,
            decoration: _inputDecoration(
              'Spesialisasi',
              prefixIcon: const Icon(
                Icons.local_hospital,
                color: AppColors.grey,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Spesialisasi tidak boleh kosong';
              }
              return null;
            },
            onChanged: (value) {
              if (_formKey.currentState != null &&
                  !_formKey.currentState!.validate()) {
                setState(() {});
              }
            },
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: doctorPhoneController,
            decoration: _inputDecoration(
              'Nomor Telepon Dokter',
              prefixIcon: const Icon(Icons.phone, color: AppColors.grey),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nomor Telepon Dokter tidak boleh kosong';
              }
              return null;
            },
            onChanged: (value) {
              if (_formKey.currentState != null &&
                  !_formKey.currentState!.validate()) {
                setState(() {});
              }
            },
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: doctorAddressController,
            decoration: _inputDecoration(
              'Alamat Dokter',
              prefixIcon: const Icon(Icons.location_on, color: AppColors.grey),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Alamat Dokter tidak boleh kosong';
              }
              return null;
            },
            onChanged: (value) {
              if (_formKey.currentState != null &&
                  !_formKey.currentState!.validate()) {
                setState(() {});
              }
            },
          ),
        ],
      );
    }
    return const SizedBox(); // Fallback if no role is selected (should not happen with default)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightSheet, // Consistent background color
      appBar: AppBar(
        title: const Text(
          'Registrasi Pengguna',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.deepPurple, // Consistent AppBar color
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ), // White back icon
      ),
      body: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterLoading) {
            // Can show a loading dialog or overlay here
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mendaftarkan akun...')),
            );
          } else if (state is RegisterSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            // Navigate to login after successful registration
            context.pushAndRemoveUntil(const LoginScreen(), (route) => false);
          } else if (state is RegisterFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // Increased padding
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Center contents
              children: [
                const SpaceHeight(20), // Top spacing

                Text(
                  'DAFTAR AKUN BARU',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.06,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPurple, // Deep purple for title
                  ),
                ),
                const SpaceHeight(30), // Spacing after title
                // Dropdown for Role Selection
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(
                      value: 'pasien',
                      child: Text(
                        'Pasien',
                        style: TextStyle(color: AppColors.black),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'keluarga',
                      child: Text(
                        'Keluarga',
                        style: TextStyle(color: AppColors.black),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'dokter',
                      child: Text(
                        'Dokter',
                        style: TextStyle(color: AppColors.black),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                      _formKey.currentState
                          ?.reset(); // Reset form when role changes
                    });
                  },
                  decoration: _inputDecoration(
                    'Pilih Role',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AppColors.grey,
                    ), // Icon for role
                  ).copyWith(
                    labelText: 'Pilih Role',
                    hintText: null,
                  ), // Clear hintText as labelText is used
                ),
                const SpaceHeight(16), // Spacing after role dropdown
                // Username and Password Fields
                TextFormField(
                  controller: usernameController,
                  decoration: _inputDecoration(
                    'Username',
                    prefixIcon: const Icon(Icons.person, color: AppColors.grey),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username tidak boleh kosong';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_formKey.currentState != null &&
                        !_formKey.currentState!.validate()) {
                      setState(() {});
                    }
                  },
                ),
                const SpaceHeight(16), // Spacing
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscureText,
                  decoration: _inputDecoration(
                    'Password',
                    prefixIcon: const Icon(Icons.lock, color: AppColors.grey),
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: AppColors.grey, // Consistent icon color
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText =
                              !_obscureText; // Toggle password visibility
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_formKey.currentState != null &&
                        !_formKey.currentState!.validate()) {
                      setState(() {});
                    }
                  },
                ),
                const SpaceHeight(20), // Spacing
                // Dynamic Form Fields based on Role
                _buildFormField(),
                const SpaceHeight(30), // Spacing before button
                // Register Button
                BlocBuilder<RegisterBloc, RegisterState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed:
                          state is RegisterLoading
                              ? null // Disable button when loading
                              : () {
                                if (_formKey.currentState!.validate()) {
                                  final request = RegisterRequestModel(
                                    username: usernameController.text.trim(),
                                    password: passwordController.text.trim(),
                                    role: selectedRole,
                                    patientName:
                                        selectedRole == 'pasien'
                                            ? patientNameController.text.trim()
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
                                            ? patientPhoneController.text.trim()
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
                                            ? doctorPhoneController.text.trim()
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
                                            ? familyPhoneController.text.trim()
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
                        minimumSize: const Size.fromHeight(55), // Taller button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // Rounded corners
                        ),
                        backgroundColor:
                            AppColors.deepPurple, // Deep purple button
                        foregroundColor: AppColors.white, // White text
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ), // Larger, bolder text
                      ),
                      child: Text(
                        state is RegisterLoading ? 'Memuat...' : 'Daftar',
                      ),
                    );
                  },
                ),
                const SpaceHeight(20), // Spacing
                // "Sudah memiliki akun?" link
                Text.rich(
                  TextSpan(
                    text: 'Sudah memiliki akun? Silahkan ',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize:
                          MediaQuery.of(context).size.width *
                          0.035, // Adjusted font size
                    ),
                    children: [
                      TextSpan(
                        text: 'Masuk disini!',
                        style: const TextStyle(
                          color: AppColors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ), // Deep purple, bold link
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                context.push(
                                  const LoginScreen(),
                                ); // Navigate to LoginScreen
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
