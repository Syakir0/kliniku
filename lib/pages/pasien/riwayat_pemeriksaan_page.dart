import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'resep_list_page.dart';

class RiwayatPemeriksaanPage extends StatelessWidget {
  final String idPasien;

  const RiwayatPemeriksaanPage({
    super.key,
    required this.idPasien,
  });

  String formatTanggal(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    return DateFormat('dd MMM yyyy', 'id_ID')
        .format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pemeriksaan')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pemeriksaan')
            .where('id_pasien', isEqualTo: idPasien)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada pemeriksaan'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final diagnosa = data['diagnosa'] ?? '-';
              final catatan = data['catatan'] ?? '';
              final tanggal = data['tanggal'] as Timestamp?;
              final createdAt = data['created_at'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    diagnosa,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      Text(
                        'Tanggal: ${formatTanggal(tanggal ?? createdAt)}',
                      ),

                      if (catatan.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Catatan: $catatan'),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.medication),
                    tooltip: 'Lihat Resep',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResepListPage(
                            idPemeriksaan: doc.id,
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
