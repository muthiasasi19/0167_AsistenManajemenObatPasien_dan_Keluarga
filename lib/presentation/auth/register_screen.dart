import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manajemen_obat/data/models/request/register_request_model.dart';
import 'package:manajemen_obat/presentation/auth/bloc/register/register_bloc.dart';
import 'package:manajemen_obat/core/components/spaces.dart';
import 'package:manajemen_obat/core/core.dart';
import 'package:intl/intl.dart';
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
  String? selectedGender;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        patientDobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

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
        borderRadius: BorderRadius.circular(12.0),
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
        borderSide: const BorderSide(color: AppColors.deepPurple, width: 2.0),
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
      fillColor: AppColors.white,
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    patientNameController.dispose();
    patientDobController.dispose();
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
          ),
          const SpaceHeight(10),
          TextFormField(
            controller: patientDobController,
            readOnly: true,
            onTap: () => _selectDate(context),
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
          ),
          const SpaceHeight(10),
          DropdownButtonFormField<String>(
            value: selectedGender,
            items: const [
              DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
              DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
            ],
            onChanged: (value) {
              setState(() {
                selectedGender = value;
              });
            },
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
          ),
        ],
      );
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightSheet,
      appBar: AppBar(
        title: const Text(
          'Registrasi Pengguna',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
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
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SpaceHeight(20),

                Text(
                  'DAFTAR AKUN BARU',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.06,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPurple,
                  ),
                ),
                const SpaceHeight(30),
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
                const SpaceHeight(16),
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
                ),
                const SpaceHeight(16),
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
                        color: AppColors.grey,
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
                ),
                const SpaceHeight(20), // Spacing
                _buildFormField(),
                const SpaceHeight(30),
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
                                            ? selectedGender
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: AppColors.deepPurple,
                        foregroundColor: AppColors.white,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(
                        state is RegisterLoading ? 'Memuat...' : 'Daftar',
                      ),
                    );
                  },
                ),
                const SpaceHeight(20),
                Text.rich(
                  TextSpan(
                    text: 'Sudah memiliki akun? Silahkan ',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                    ),
                    children: [
                      TextSpan(
                        text: 'Masuk disini!',
                        style: const TextStyle(
                          color: AppColors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                context.push(const LoginScreen());
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
