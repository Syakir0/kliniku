import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pemeriksaan_page.dart';

class AntrianDokterPage extends StatelessWidget {
  AntrianDokterPage({super.key});

  final String uidDokter = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Antrian Pasien')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('antrian')
            .where('id_dokter', isEqualTo: uidDokter)
            .where('status', isEqualTo: 'menunggu')
            .orderBy('nomor')
            .snapshots(),
        builder: (context, snapshot) {
          // ERROR FIRESTORE
          if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat data antrian'));
          }

          // LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // DATA KOSONG
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada antrian pasien'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final nomor = data['nomor'] ?? '-';
              final idPasien = data['id_pasien'] ?? 'Tidak diketahui';
              final status = data['status'] ?? '-';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(child: Text(nomor.toString())),
                  title: Text('Pasien: $idPasien'),
                  subtitle: Text('Status: $status'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PemeriksaanPage(
                            idJanji: data['id_janji'],
                            idPasien: idPasien,
                            idDokter: uidDokter,
                          ),
                        ),
                      );
                    },
                    child: const Text('Periksa'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
