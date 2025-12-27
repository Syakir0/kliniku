import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'resep_list_page.dart';

class RiwayatPemeriksaanPage extends StatelessWidget {
  final String idPasien;

  const RiwayatPemeriksaanPage({
    super.key,
    required this.idPasien,
  });

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

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                    data['diagnosa'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['catatan'] != null &&
                          data['catatan'].toString().isNotEmpty)
                        Text('Catatan: ${data['catatan']}'),
                      Text(
                        'Tanggal: ${(data['created_at'] as Timestamp).toDate().toString().split(" ")[0]}',
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.medication),
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
