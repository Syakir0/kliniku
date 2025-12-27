import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'antrian_dokter_page.dart';

class DokterPage extends StatelessWidget {
  const DokterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Dokter'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selamat datang, Dokter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AntrianDokterPage(), // ⬅️ TANPA const
                  ),
                );
              },
              child: const Text('Lihat Antrian Pasien'),
            ),
          ],
        ),
      ),
    );
  }
}
