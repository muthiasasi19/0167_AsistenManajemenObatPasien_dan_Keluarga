import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manajemen_obat/presentation/family/bloc/family_bloc.dart';
import 'package:manajemen_obat/data/models/response/login_response_model.dart';

class KeluargaProfileScreen extends StatefulWidget {
  const KeluargaProfileScreen({super.key});

  @override
  State<KeluargaProfileScreen> createState() => _KeluargaProfileScreenState();
}

class _KeluargaProfileScreenState extends State<KeluargaProfileScreen> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    final familyState = context.read<FamilyBloc>().state;
    if (familyState is FamilyLoaded) {
      _currentUser = familyState.familyUserData;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Keluarga"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<FamilyBloc>().add(const LoadFamilyDataRequested());
            },
            tooltip: 'Refresh Profil',
          ),
        ],
      ),
      body: BlocConsumer<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (state is FamilyLoaded) {
            setState(() {
              _currentUser = state.familyUserData;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data profil diperbarui!')),
            );
          } else if (state is FamilyLoading) {
          } else if (state is FamilyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error memuat profil: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          if (_currentUser == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data profil...'),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Nama: ${_currentUser!.namaKeluarga ?? _currentUser!.username ?? 'N/A'}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text("Role: ${_currentUser!.role ?? 'N/A'}"),
                Text("ID Keluarga Unik: ${_currentUser!.idKeluarga ?? 'N/A'}"),
                Text(
                  "ID Global Keluarga: ${_currentUser!.familyGlobalId?.toString() ?? 'N/A'}",
                ),
                Text(
                  "Nomor Telepon: ${_currentUser!.nomorTeleponKeluarga ?? 'N/A'}",
                ),
                Text("Alamat: ${_currentUser!.alamatKeluarga ?? 'N/A'}"),
              ],
            ),
          );
        },
      ),
    );
  }
}
