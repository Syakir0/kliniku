import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AntrianPasienPage extends StatelessWidget {
  const AntrianPasienPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Antrian Saya')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('janji')
            .where('id_pasien', isEqualTo: uid)
            .orderBy('tanggal', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada antrian'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'];

              Color statusColor;
              IconData statusIcon;
              String statusText;

              switch (status) {
                case 'batal':
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                  statusText = 'Dibatalkan';
                  break;
                case 'selesai':
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  statusText = 'Selesai';
                  break;
                default:
                  statusColor = Colors.orange;
                  statusIcon = Icons.access_time;
                  statusText = 'Menunggu';
              }

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(statusIcon, color: statusColor),
                  title: Text(
                    'Dr. ${data['nama_dokter']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Poli: ${data['poli']}'),
                      Text('Nomor Antrian: ${data['nomer_antrian']}'),
                      Text(
                        'Tanggal: ${(data['tanggal'] as Timestamp).toDate().toString().split(' ')[0]}',
                      ),
                      Text(
                        'Status: $statusText',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // ===== TOMBOL BATAL =====
                  trailing: status == 'menunggu'
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Batalkan Janji'),
                                content: const Text(
                                  'Apakah Anda yakin ingin membatalkan janji ini?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Tidak'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await firestore
                                          .collection('janji')
                                          .doc(doc.id)
                                          .update({
                                            'status': 'batal',
                                            'update_at': Timestamp.now(),
                                          });

                                      Navigator.pop(context);
                                    },
                                    child: const Text('Ya, Batalkan'),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : null,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
