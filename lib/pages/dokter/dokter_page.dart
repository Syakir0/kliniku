import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import 'antrian_dokter_page.dart';
import 'profile_dokter.dart';

class DokterPage extends StatelessWidget {
  const DokterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final uid = FirebaseAuth.instance.currentUser!.uid;

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
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text('Data dokter tidak ditemukan');
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final namaDokter = data['nama'] ?? 'Dokter';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Selamat datang, dr. $namaDokter',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // ===== PROFILE DOKTER =====
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Profil Dokter'),
                    subtitle: const Text('Lihat & edit data dokter'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileDokterPage(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ===== ANTRIAN =====
                ElevatedButton.icon(
                  icon: const Icon(Icons.queue),
                  label: const Text('Lihat Antrian Pasien'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AntrianDokterPage(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
