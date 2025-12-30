import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'detail_resep_page.dart';
import '../login/login_page.dart';

class ApotekPage extends StatelessWidget {
  const ApotekPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Apotek'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('resep')
            .orderBy('tanggal', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada resep'));
          }

          final resepList = snapshot.data!.docs;

          return ListView.builder(
            itemCount: resepList.length,
            itemBuilder: (context, index) {
              final doc = resepList[index];
              final data = doc.data() as Map<String, dynamic>;

              final status = data['status_resep'] ?? 'menunggu_apotek';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    'Pasien: ${data['nama_pasien'] ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dokter: ${data['nama_dokter'] ?? '-'}'),
                      const SizedBox(height: 6),
                      Chip(
                        label: Text(
                          status == 'selesai' ? 'SELESAI' : 'MENUNGGU',
                        ),
                        backgroundColor: status == 'selesai'
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                      ),
                    ],
                  ),

                  // ⛔ tombol hapus NONAKTIF kalau selesai
                  trailing: status == 'selesai'
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.arrow_forward_ios, size: 16),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailResepPage(resepId: doc.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
