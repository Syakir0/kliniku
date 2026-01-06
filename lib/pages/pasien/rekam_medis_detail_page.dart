import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'resep_list_page.dart';

class RekamMedisDetailPage extends StatelessWidget {
  final String idPasien;

  const RekamMedisDetailPage({
    super.key,
    required this.idPasien,
  });

  String formatTanggal(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    return DateFormat('dd MMM yyyy', 'id_ID').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekam Medis Pasien'),
        backgroundColor: Colors.cyan[700],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: firestore.collection('rekam_medis').doc(idPasien).get(),
        builder: (context, snapshotRM) {
          if (snapshotRM.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rm = snapshotRM.data?.data() as Map<String, dynamic>?;

          return Column(
            children: [
              // ================= REKAM MEDIS =================
              Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rekam Medis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan[800],
                        ),
                      ),
                      const Divider(thickness: 1),
                      _item('Golongan Darah', rm?['golongan_darah']),
                      _item('Alergi', rm?['alergi']),
                      _item('Penyakit Kronis', rm?['penyakit_kronis']),
                      _item('Tinggi Badan', rm?['tinggi_badan']),
                      _item('Berat Badan', rm?['berat_badan']),
                      _item('Riwayat Operasi', rm?['riwayat_operasi']),
                      _item('Catatan Umum', rm?['catatan_umum']),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ================= RIWAYAT PEMERIKSAAN =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Riwayat Pemeriksaan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyan[800],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('pemeriksaan')
                      .where('id_pasien', isEqualTo: idPasien)
                      .orderBy('created_at', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Belum ada pemeriksaan'));
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              data['diagnosa'] ?? '-',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Tanggal: ${formatTanggal(data['tanggal'] ?? data['created_at'])}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                if ((data['catatan'] ?? '').toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Catatan: ${data['catatan']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.medication, color: Colors.cyan[700]),
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
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _item(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$label : ${value ?? "-"}',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
