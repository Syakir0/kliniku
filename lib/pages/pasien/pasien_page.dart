import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import 'buat_janji_page.dart';
import 'antrian_pasien_page.dart';
import 'riwayat_pemeriksaan_page.dart';

class PasienPage extends StatelessWidget {
  const PasienPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pasien'),
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
              'Selamat datang, Pasien',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            // ===== BUAT JANJI =====
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text('Buat Janji'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BuatJanjiPage()),
                );
              },
            ),

            const SizedBox(height: 12),

            // ===== LIHAT ANTRIAN =====
            ElevatedButton.icon(
              icon: const Icon(Icons.queue),
              label: const Text('Lihat Antrian'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AntrianPasienPage()),
                );
              },
            ),

            const SizedBox(height: 12),

            // ===== RIWAYAT PEMERIKSAAN =====
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Riwayat Pemeriksaan'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RiwayatPemeriksaanPage(idPasien: uid),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
