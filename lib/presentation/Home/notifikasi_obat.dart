import 'package:flutter/material.dart';

class NotifikasiObat extends StatelessWidget {
  const NotifikasiObat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Notifikasi Obat')),
      body: const Center(
        child: Text(
          'Halaman Pengaturan Notifikasi Obat',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
