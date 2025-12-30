import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pemeriksaan_page.dart';
import 'package:intl/intl.dart';

class AntrianDokterPage extends StatelessWidget {
  AntrianDokterPage({super.key});

  final String uidDokter = FirebaseAuth.instance.currentUser!.uid;

  // ✅ FORMAT TANGGAL
  String formatTanggal(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final date = timestamp.toDate();
    return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Antrian Pasien')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('janji')
            .where('id_dokter', isEqualTo: uidDokter)
            .orderBy('id_dokter')
            .orderBy('status')
            .orderBy('nomer_antrian')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat data antrian'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada antrian pasien'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final nomor = data['nomer_antrian'];
              final namaPasien = data['nama_pasien'] ?? '-';
              final noHp = data['no_hp_pasien'] ?? '-';
              final poli = data['poli'] ?? '-';
              final jam =
                  '${data['jam_mulai'] ?? '-'} - ${data['jam_selesai'] ?? '-'}';
              final status = data['status'] ?? 'menunggu';

              // ✅ AMBIL & FORMAT TANGGAL
              final tanggal =
                  formatTanggal(data['tanggal'] as Timestamp?);

              Color statusColor;
              switch (status) {
                case 'selesai':
                  statusColor = Colors.green;
                  break;
                case 'batal':
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.orange;
              }

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(child: Text(nomor.toString())),
                  title: Text(
                    namaPasien,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tanggal: $tanggal'), // ✅ TAMPIL
                      Text('Jam: $jam'),
                      Text('Poli: $poli'),
                      Text('No HP: $noHp'),
                      Text(
                        'Status: ${status.toUpperCase()}',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    child: const Text('Periksa'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PemeriksaanPage(
                            idJanji: docs[index].id,
                            idPasien: data['id_pasien'],
                            idDokter: uidDokter,
                          ),
                        ),
                      );
                    },
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
